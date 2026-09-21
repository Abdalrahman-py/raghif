import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// Fired by a Postgres trigger (trigger_notify_batch, on public.purchases)
// whenever notify_next_batch() flips a batch to 'notified'. Pushes to every
// registered device of the buyers in *that batch*.
//
// verify_jwt is OFF because the caller is a DB trigger via pg_net, which has
// no Supabase session to present. Authorization is instead a shared secret
// in `x-notify-batch-secret`, generated into Vault by the migration and
// handed to this function as the `NOTIFY_BATCH_SECRET` env var. Without that
// check the endpoint is an open push-spam relay: store ids are world-
// readable under the `stores` RLS policy, so anyone could alert every
// waiting buyer in any store. Fails closed — an unset secret rejects
// everything rather than reverting to open.
//
// Requires the `FCM_SERVICE_ACCOUNT` secret (a Firebase service-account
// JSON key, as one line) to actually send pushes — set via:
//   supabase secrets set FCM_SERVICE_ACCOUNT='<json>' --project-ref mgmerkaokkffsypnkryj
// Until that secret exists this degrades gracefully (logs + returns
// sent:0) rather than failing the trigger.
//
// ponytail: plain !== on the shared secret, not a constant-time compare —
// remote timing analysis across the network on a 256-bit random hex is not
// a practical attack. Swap in crypto.timingSafeEqual if this ever guards
// something weaker than a full-entropy secret.

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVICE_ACCOUNT = Deno.env.get("FCM_SERVICE_ACCOUNT");
const NOTIFY_BATCH_SECRET = Deno.env.get("NOTIFY_BATCH_SECRET");

// Must match NotificationService.channelId and the manifest's
// default_notification_channel_id, or backgrounded pushes get filed under
// Android's auto-created "Miscellaneous" channel at default importance.
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

async function getFcmAccessToken(
  serviceAccount: { client_email: string; private_key: string },
): Promise<string | null> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${b64url(JSON.stringify(header))}.${
    b64url(JSON.stringify(claim))
  }`;

  const pem = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const keyBytes = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${b64url(new Uint8Array(signature))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:
      `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });
  if (!res.ok) {
    console.error("FCM token exchange failed", await res.text());
    return null;
  }
  const data = await res.json();
  return data.access_token ?? null;
}

Deno.serve(async (req: Request) => {
  if (!NOTIFY_BATCH_SECRET) {
    console.error("notify-batch: NOTIFY_BATCH_SECRET not set, refusing");
    return Response.json({ error: "not configured" }, { status: 503 });
  }
  if (req.headers.get("x-notify-batch-secret") !== NOTIFY_BATCH_SECRET) {
    return Response.json({ error: "unauthorized" }, { status: 401 });
  }

  // deno-lint-ignore no-explicit-any
  let body: any;
  try {
    body = await req.json();
  } catch {
    return Response.json({ error: "invalid JSON" }, { status: 400 });
  }

  const { storeId, purchaseDate, batchNumber } = body;
  if (!storeId || !purchaseDate || batchNumber == null) {
    return Response.json(
      { error: "missing storeId/purchaseDate/batchNumber" },
      { status: 400 },
    );
  }

  const { data: store } = await admin.from("stores").select("name").eq(
    "id",
    storeId,
  ).single();

  // Scoped to this batch. Without the batch_number filter every release
  // re-pushes to all earlier batches that are still 'notified' (i.e. not yet
  // collected), so batch 2 re-alerts batch 1, batch 3 re-alerts 1 and 2.
  const { data: notifiedPurchases } = await admin
    .from("purchases")
    .select("user_id")
    .eq("store_id", storeId)
    .eq("purchase_date", purchaseDate)
    .eq("batch_number", batchNumber)
    .eq("status", "notified");

  const userIds = [
    // deno-lint-ignore no-explicit-any
    ...new Set((notifiedPurchases ?? []).map((p: any) => p.user_id)),
  ];
  if (userIds.length === 0) {
    return Response.json({ sent: 0, reason: "no notified purchases" });
  }

  const { data: tokens } = await admin
    .from("device_tokens")
    .select("fcm_token")
    .in("user_id", userIds);

  // deno-lint-ignore no-explicit-any
  const fcmTokens = (tokens ?? []).map((t: any) => t.fcm_token as string);
  if (fcmTokens.length === 0) {
    return Response.json({ sent: 0, reason: "no device tokens registered" });
  }

  if (!FCM_SERVICE_ACCOUNT) {
    console.log(
      "notify-batch: FCM_SERVICE_ACCOUNT not set, skipping push send",
    );
    return Response.json({
      sent: 0,
      reason: "FCM not configured (FCM_SERVICE_ACCOUNT secret missing)",
    });
  }

  const serviceAccount = JSON.parse(FCM_SERVICE_ACCOUNT);
  const accessToken = await getFcmAccessToken(serviceAccount);
  if (!accessToken) {
    return Response.json({ sent: 0, reason: "FCM token exchange failed" });
  }

  let sent = 0;
  for (const token of fcmTokens) {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: {
              title: "دفعتك جاهزة",
              body: `${
                store?.name ?? "المخبز"
              }: حان دورك لاستلام الخبز`,
            },
            android: {
              priority: "high",
              notification: { channel_id: FCM_CHANNEL_ID },
            },
          },
        }),
      },
    );
    if (res.ok) sent++;
    else console.error("FCM send failed", await res.text());
  }

  return Response.json({ sent, total: fcmTokens.length });
});
