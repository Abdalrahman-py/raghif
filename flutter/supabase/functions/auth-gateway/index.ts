import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// Custom national-ID + PIN auth on top of Supabase Auth. PIN verification
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

// Demo accounts seeded by the `seed-demo` action — mirrors
// flutter/lib/core/auth/demo_accounts.dart. Kept in sync manually; these
// are prototype/demo credentials, not secrets. Pre-verified, matching the
// local drift AuthRepositoryImpl.ensureSeeded() demo accounts.
const DEMO_ACCOUNTS = [
  {
    phone: "0599111111",
    pin: "1234",
    nationalId: "900111222",
    name: "أحمد ناصر",
    jawwalPayNumber: "0599000001",
    role: "buyer",
  },
  {
    phone: "0599222222",
    pin: "1234",
    nationalId: "900333444",
    name: "صاحب المخبز",
    jawwalPayNumber: "0599000002",
    role: "owner",
  },
];

function syntheticEmail(nationalId: string): string {
  const safe = nationalId.replace(/[^a-zA-Z0-9]/g, "");
  return `nid-${safe}@raghif.internal`;
}

async function mintSession(email: string) {
  const { data: linkData, error: linkError } = await admin.auth.admin
    .generateLink({ type: "magiclink", email });
  if (linkError || !linkData?.properties?.hashed_token) {
    throw new Error(linkError?.message ?? "failed to generate session token");
  }
  const tokenHash = linkData.properties.hashed_token;

  const { data: verifyData, error: verifyError } = await admin.auth.verifyOtp({
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
    nationalId: profile.national_id,
    name: profile.name,
    role: profile.role,
    jawwalPayNumber: profile.jawwal_pay_number,
    verificationStatus: profile.verification_status,
  };
}

// deno-lint-ignore no-explicit-any
function hasId(profile: any): boolean {
  return !!profile && profile.id != null;
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
        const { phone, nationalId } = body;
        const { data, error } = await admin.rpc("check_availability", {
          p_phone: phone ?? "",
          p_national_id: nationalId ?? "",
        });
        if (error) throw error;
        const row = Array.isArray(data) ? data[0] : data;
        return json({
          phoneExists: !!row?.phone_exists,
          nationalIdExists: !!row?.national_id_exists,
        });
      }

      case "seed-demo": {
        const results: string[] = [];
        for (const demo of DEMO_ACCOUNTS) {
          const email = syntheticEmail(demo.nationalId);
          const { data: created, error: createError } = await admin.auth.admin
            .createUser({
              email,
              email_confirm: true,
              user_metadata: { national_id: demo.nationalId },
            });
          if (createError || !created?.user) {
            results.push(`${demo.nationalId}: already exists`);
            continue;
          }
          const { data: profile, error: profileError } = await admin.rpc(
            "create_profile",
            {
              p_id: created.user.id,
              p_phone: demo.phone,
              p_national_id: demo.nationalId,
              p_pin: demo.pin,
              p_name: demo.name,
              p_jawwal_pay_number: demo.jawwalPayNumber,
              p_role: demo.role,
              p_verification_status: "verified",
            },
          );
          if (profileError || !hasId(profile)) {
            await admin.auth.admin.deleteUser(created.user.id);
            results.push(`${demo.nationalId}: profile failed - ${profileError?.message}`);
            continue;
          }
          results.push(`${demo.nationalId}: seeded`);
        }
        return json({ seeded: true, results });
      }

      case "register": {
        const { phone, pin, nationalId, name, jawwalPayNumber } = body;
        if (!phone || !pin || !nationalId || !name) {
          return json({ error: "missing required fields" }, 400);
        }
        const email = syntheticEmail(nationalId);
        const { data: created, error: createError } = await admin.auth.admin
          .createUser({
            email,
            email_confirm: true,
            user_metadata: { national_id: nationalId },
          });
        if (createError || !created?.user) {
          throw new Error(createError?.message ?? "failed to create account");
        }

        try {
          // Role is never taken from client input — always 'buyer' for
          // self-registration; only `seed-demo` (server-fixed accounts) sets
          // 'owner'. verification_status stays the 'pending' default — only
          // seeded demo accounts are pre-verified.
          const { data: profile, error: profileError } = await admin.rpc(
            "create_profile",
            {
              p_id: created.user.id,
              p_phone: phone,
              p_national_id: nationalId,
              p_pin: pin,
              p_name: name,
              p_jawwal_pay_number: jawwalPayNumber ?? null,
            },
          );
          if (profileError || !hasId(profile)) {
            throw new Error(profileError?.message ?? "failed to create profile");
          }

          const session = await mintSession(email);
          return json({
            accessToken: session.access_token,
            refreshToken: session.refresh_token,
            profile: profileResponse(profile),
          });
        } catch (inner) {
          // Roll back the auth user (profile cascade-deletes with it) so the
          // client can safely retry registration with the same identifiers
          // instead of getting stuck on an orphaned, session-less account.
          await admin.auth.admin.deleteUser(created.user.id);
          throw inner;
        }
      }

      case "login-pin": {
        const { identifier, by, pin } = body;
        if (!identifier || !pin) {
          return json({ error: "missing required fields" }, 400);
        }
        const { data: profile, error } = await admin.rpc(
          "verify_pin_and_get_profile",
          {
            p_identifier: identifier,
            p_by: by === "phone" ? "phone" : "national_id",
            p_pin: pin,
          },
        );
        if (error || !hasId(profile)) {
          return json({ error: "invalid credentials" }, 401);
        }
        const email = syntheticEmail(profile.national_id);
        const session = await mintSession(email);
        return json({
          accessToken: session.access_token,
          refreshToken: session.refresh_token,
          profile: profileResponse(profile),
        });
      }

      case "otp-request": {
        const { nationalId } = body;
        const { data: profile, error } = await admin.rpc(
          "find_profile_by_national_id",
          { p_national_id: nationalId },
        );
        if (error || !hasId(profile)) {
          return json({ error: "not found" }, 404);
        }
        // Mock OTP — no real SMS gateway yet (spec.md open question). Matches
        // the existing on-screen mock code.
        return json({ otpCode: "4821", phone: profile.phone });
      }

      case "otp-confirm": {
        const { nationalId } = body;
        const { data: profile, error } = await admin.rpc(
          "find_profile_by_national_id",
          { p_national_id: nationalId },
        );
        if (error || !hasId(profile)) {
          return json({ error: "not found" }, 404);
        }
        const email = syntheticEmail(profile.national_id);
        const session = await mintSession(email);
        return json({
          accessToken: session.access_token,
          refreshToken: session.refresh_token,
          profile: profileResponse(profile),
        });
      }

      default:
        return json({ error: `unknown action: ${action}` }, 400);
    }
  } catch (err) {
    return json({ error: (err as Error).message ?? "internal error" }, 500);
  }
});
