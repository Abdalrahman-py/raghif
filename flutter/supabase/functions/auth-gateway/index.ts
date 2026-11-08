import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// Custom phone-number + PIN auth on top of Supabase Auth. PIN verification
// and profile creation happen in Postgres (service-role-only RPCs — see
// migration `auth_gateway_rpcs`). A session is minted by generating a
// magic-link token for a synthetic, never-emailed address and immediately
// redeeming it server-side (`generateLink` + `verifyOtp`) — this sidesteps
// the still-unresolved real SMS/OTP gateway (spec.md open question) while
// still producing a real Supabase session with a genuine `auth.uid()` for
// RLS. See docs/supabase-migration-plan.md.

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

// There is deliberately no code-based sign-in ("forgot PIN" by SMS/OTP): with no
// SMS gateway a code can only be shown to the person asking, which lets anyone
// who knows a phone number in. A forgotten PIN is reset by support through the
// admin panel until a real gateway exists. `otp-request` / `otp-confirm` answer
// 410 so an old app build fails closed.

// PINs that are trivial to guess are refused at registration, the same list
// `change_my_pin` uses in the database.
const WEAK_PINS = new Set([
  "0123", "1234", "2345", "3456", "4567", "5678", "6789",
  "3210", "4321", "5432", "6543", "7654", "8765", "9876",
]);
function pinProblem(pin: unknown): "invalid_pin" | "weak_pin" | null {
  if (typeof pin !== "string" || !/^[0-9]{4}$/.test(pin)) return "invalid_pin";
  if (/^(\d)\1{3}$/.test(pin) || WEAK_PINS.has(pin)) return "weak_pin";
  return null;
}

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

// The sign-in address is never emailed. New accounts get a random one (not
// derived from the phone number, which support may change).
// Read it back from the auth user rather than recomputing it.
async function emailOf(userId: string): Promise<string> {
  const { data, error } = await admin.auth.admin.getUserById(userId);
  if (error || !data?.user?.email) {
    throw new Error(error?.message ?? "account has no sign-in address");
  }
  return data.user.email;
}

async function mintSession(email: string) {
  const { data: linkData, error: linkError } = await admin.auth.admin
    .generateLink({ type: "magiclink", email });
  if (linkError || !linkData?.properties?.hashed_token) {
    throw new Error(linkError?.message ?? "failed to generate session token");
  }
  const tokenHash = linkData.properties.hashed_token;

  // A throwaway client: verifyOtp stores the resulting session on the client
  // it is called on, and a service-role client that holds a user session starts
  // sending that user's token, so every later call in this warm instance would
  // run as `authenticated` and be refused ("permission denied for function").
  const redeemer = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: verifyData, error: verifyError } = await redeemer.auth.verifyOtp({
    type: "magiclink",
    token_hash: tokenHash,
  });
  if (verifyError || !verifyData.session) {
    throw new Error(verifyError?.message ?? "failed to verify session token");
  }
  return verifyData.session;
}

// deno-lint-ignore no-explicit-any
function profileResponse(profile: any) {
  return {
    remoteId: profile.id,
    phone: profile.phone,
    name: profile.name,
    role: profile.role,
    verificationStatus: profile.verification_status,
  };
}

// deno-lint-ignore no-explicit-any
function hasId(profile: any): boolean {
  return !!profile && profile.id != null;
}

// Why this identity may not sign in right now, or null when it may. The PIN
// (or code) has already checked out by the time we ask, so telling the caller
// the account is disabled reveals nothing to someone who does not hold it.
// Fails closed on a real error; only a missing function (the migration that
// adds it is not applied yet) is treated as "no block", so deploying this file
// before the database cannot lock everybody out.
async function loginBlock(profileId: string): Promise<string | null> {
  const { data, error } = await admin.rpc("account_login_block", {
    p_user: profileId,
  });
  if (error) {
    if (error.code === "PGRST202" || /could not find the function/i.test(error.message)) {
      return null;
    }
    throw new Error(error.message);
  }
  return typeof data === "string" ? data : null;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405, headers: CORS_HEADERS });
  }

  // deno-lint-ignore no-explicit-any
  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid JSON body" }, 400);
  }

  const action = body.action as string;

  try {
    switch (action) {
      case "check-availability": {
        const { phone } = body;
        const { data, error } = await admin.rpc("check_availability", {
          p_phone: phone ?? "",
        });
        if (error) throw error;
        const row = Array.isArray(data) ? data[0] : data;
        return json({ phoneExists: !!row?.phone_exists });
      }

      case "register": {
        const { phone, pin, name } = body;
        if (!phone || !pin || !name) {
          return json({ error: "missing required fields" }, 400);
        }
        // The phone number is also the Jawwal Pay wallet number.
        if (typeof phone !== "string" || !/^05[69][0-9]{7}$/.test(phone)) {
          return json({ error: "invalid_phone" }, 400);
        }
        const problem = pinProblem(pin);
        if (problem) return json({ error: problem }, 400);
        const { data: taken, error: takenError } = await admin.rpc(
          "check_availability",
          { p_phone: phone },
        );
        // Never treat "could not ask" as "not taken".
        if (takenError) throw new Error(takenError.message);
        const takenRow = Array.isArray(taken) ? taken[0] : taken;
        if (takenRow?.phone_exists) {
          return json({ error: "phone already registered" }, 409);
        }
        const { data: created, error: createError } = await admin.auth.admin
          .createUser({
            email: `u-${crypto.randomUUID()}@raghif.internal`,
            email_confirm: true,
          });
        if (createError || !created?.user) {
          throw new Error(createError?.message ?? "failed to create account");
        }

        try {
          // Role is never taken from client input: self-registration is always
          // 'buyer'. verification_status stays the 'pending' default until the
          // wallet number is verified.
          const { data: profile, error: profileError } = await admin.rpc(
            "create_profile",
            {
              p_id: created.user.id,
              p_phone: phone,
              p_pin: pin,
              p_name: name,
            },
          );
          if (profileError || !hasId(profile)) {
            throw new Error(profileError?.message ?? "failed to create profile");
          }

          const session = await mintSession(created.user.email!);
          return json({
            accessToken: session.access_token,
            refreshToken: session.refresh_token,
            profile: profileResponse(profile),
          });
        } catch (inner) {
          // Roll back the auth user (profile cascade-deletes with it) so the
          // client can safely retry registration with the same number instead
          // of getting stuck on an orphaned, session-less account.
          await admin.auth.admin.deleteUser(created.user.id);
          throw inner;
        }
      }

      case "login-pin": {
        const { phone, pin } = body;
        if (!phone || !pin) {
          return json({ error: "missing required fields" }, 400);
        }
        const { data: attempt, error } = await admin.rpc("login_attempt", {
          p_phone: phone,
          p_pin: pin,
        });
        if (error) throw new Error(error.message);
        if (attempt?.result === "locked") {
          return json(
            { error: "login_locked", retryAfter: attempt.retry_after ?? 900 },
            429,
          );
        }
        const profile = attempt?.profile;
        if (attempt?.result !== "ok" || !hasId(profile)) {
          return json({ error: "invalid credentials" }, 401);
        }
        const blocked = await loginBlock(profile.id);
        if (blocked) return json({ error: blocked }, 403);
        const email = await emailOf(profile.id);
        const session = await mintSession(email);
        return json({
          accessToken: session.access_token,
          refreshToken: session.refresh_token,
          profile: profileResponse(profile),
        });
      }

      case "otp-request":
      case "otp-confirm":
        return json({ error: "code sign-in is disabled" }, 410);

      default:
        return json({ error: `unknown action: ${action}` }, 400);
    }
  } catch (err) {
    return json({ error: (err as Error).message ?? "internal error" }, 500);
  }
});
