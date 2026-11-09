import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { type Deps, handle, type InboxRow } from "./core.ts";

// Pushes one notification_inbox row to its owner's devices. See core.ts.
//
// verify_jwt is OFF: the caller is a database trigger (pg_net) with no
// Supabase session. It authenticates with the NOTIFY_BATCH_SECRET shared
// secret instead, and fails closed when that secret is unset.
//
// Needs the FCM_SERVICE_ACCOUNT secret (Firebase service-account JSON, one
// line) to actually send:
//   supabase secrets set FCM_SERVICE_ACCOUNT='<json>' --project-ref mgmerkaokkffsypnkryj
// Until then it logs and returns sent:0, so the trigger never fails.

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVICE_ACCOUNT = Deno.env.get("FCM_SERVICE_ACCOUNT");
const NOTIFY_BATCH_SECRET = Deno.env.get("NOTIFY_BATCH_SECRET");

// Same channel as notify-batch and the app's manifest default.
const FCM_CHANNEL_ID = "queue_notifications";

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

function b64url(bytes: Uint8Array | string): string {
  const bin = typeof bytes === "string"
    ? bytes
    : String.fromCharCode(...bytes);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

// deno-lint-ignore no-explicit-any
let serviceAccount: any = null;
if (FCM_SERVICE_ACCOUNT) {
  try {
    serviceAccount = JSON.parse(FCM_SERVICE_ACCOUNT);
  } catch {
    console.error("send-push: FCM_SERVICE_ACCOUNT is not valid JSON");
  }
}

// One Google access token serves every send in this invocation (and, while the
// isolate stays warm, the next ones until it nears expiry).
let cached: { token: string; expiresAt: number } | null = null;

async function accessToken(): Promise<string | null> {
  if (!serviceAccount) return null;
  const nowMs = Date.now();
  if (cached && cached.expiresAt - 60_000 > nowMs) return cached.token;

  const now = Math.floor(nowMs / 1000);
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }))}.${
    b64url(JSON.stringify(claim))
  }`;
  const pem = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const key = await crypto.subtle.importKey(
    "pkcs8",
    Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:
      `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${unsigned}.${
        b64url(new Uint8Array(signature))
      }`,
  });
  if (!res.ok) {
    console.error("FCM token exchange failed", res.status);
    return null;
  }
  const data = await res.json();
  if (!data.access_token) return null;
  cached = { token: data.access_token, expiresAt: nowMs + 3_500_000 };
  return cached.token;
}

const deps: Deps = {
  secret: NOTIFY_BATCH_SECRET,

  loadInbox: async (id) => {
    const { data } = await admin
      .from("notification_inbox")
      .select("user_id, title, body, kind")
      .eq("id", id)
      .maybeSingle();
    return (data as InboxRow | null) ?? null;
  },

  loadTokens: async (userId) => {
    const { data } = await admin
      .from("device_tokens")
      .select("fcm_token")
      .eq("user_id", userId);
    // deno-lint-ignore no-explicit-any
    return (data ?? []).map((t: any) => t.fcm_token as string);
  },

  deleteTokens: async (tokens) => {
    await admin.from("device_tokens").delete().in("fcm_token", tokens);
  },

  fcm: {
    configured: serviceAccount != null,
    send: async (token, message) => {
      const bearer = await accessToken();
      if (!bearer) return "error";
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${bearer}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: message.title, body: message.body },
              data: message.data,
              android: {
                priority: "high",
                notification: { channel_id: FCM_CHANNEL_ID },
              },
            },
          }),
        },
      );
      if (res.ok) return "ok";
      const text = await res.text();
      // 404 / UNREGISTERED: the app was uninstalled or the token rotated.
      if (res.status === 404 || text.includes("UNREGISTERED")) {
        return "invalid_token";
      }
      console.error("FCM send failed", res.status);
      return "error";
    },
  },
};

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return Response.json({ error: "method not allowed" }, { status: 405 });
  }
  // deno-lint-ignore no-explicit-any
  let body: any;
  try {
    body = await req.json();
  } catch {
    return Response.json({ error: "invalid JSON" }, { status: 400 });
  }
  try {
    const out = await handle(req.headers, body, deps);
    return Response.json(out.body, { status: out.status });
  } catch (e) {
    console.error("send-push failure:", (e as Error).message);
    return Response.json({ error: "internal error" }, { status: 500 });
  }
});
