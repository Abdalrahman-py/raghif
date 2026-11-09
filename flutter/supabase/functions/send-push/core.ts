// Logic of the send-push edge function, with everything outside injected so it
// can be tested without Deno, Postgres or Firebase.
//
// A Postgres trigger on public.notification_inbox calls this with
// { inboxId } for the kinds no other trigger already pushes (postponed and
// announcement; "confirmed" and "ready" go out through notify-batch). We read
// the row, find the owner's devices and send it through FCM, so the inbox row
// and the push are always the same message.
//
// Caller authentication is the shared secret in `x-notify-batch-secret` (the
// same Vault secret the other push triggers use); there is no Supabase session
// to present from a database trigger, so verify_jwt is off for this function.

export interface InboxRow {
  user_id: string;
  title: string;
  body: string;
  kind: string;
}

export type SendResult = "ok" | "invalid_token" | "error";

export interface Deps {
  /** Value of NOTIFY_BATCH_SECRET; undefined when the function is unconfigured. */
  secret: string | undefined;
  loadInbox(id: string): Promise<InboxRow | null>;
  loadTokens(userId: string): Promise<string[]>;
  deleteTokens(tokens: string[]): Promise<void>;
  fcm: {
    configured: boolean;
    send(
      token: string,
      message: { title: string; body: string; data: Record<string, string> },
    ): Promise<SendResult>;
  };
}

export interface Reply {
  status: number;
  body: Record<string, unknown>;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Compares without bailing out at the first differing character. */
export function safeEqual(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  }
  return diff === 0;
}

export async function handle(
  headers: { get(name: string): string | null },
  // deno-lint-ignore no-explicit-any
  body: any,
  deps: Deps,
): Promise<Reply> {
  if (!deps.secret) {
    console.error("send-push: NOTIFY_BATCH_SECRET not set, refusing");
    return { status: 503, body: { error: "not configured" } };
  }
  const given = headers.get("x-notify-batch-secret");
  if (!given || !safeEqual(given, deps.secret)) {
    return { status: 401, body: { error: "unauthorized" } };
  }

  const inboxId = typeof body?.inboxId === "string" ? body.inboxId : "";
  if (!UUID.test(inboxId)) {
    return { status: 400, body: { error: "inboxId required" } };
  }

  const row = await deps.loadInbox(inboxId);
  if (!row) return { status: 200, body: { sent: 0, reason: "no such notification" } };

  const tokens = await deps.loadTokens(row.user_id);
  if (tokens.length === 0) {
    return { status: 200, body: { sent: 0, reason: "no device tokens registered" } };
  }
  if (!deps.fcm.configured) {
    console.log("send-push: FCM_SERVICE_ACCOUNT not set, skipping push send");
    return {
      status: 200,
      body: { sent: 0, reason: "FCM not configured (FCM_SERVICE_ACCOUNT secret missing)" },
    };
  }

  let sent = 0;
  const dead: string[] = [];
  for (const token of tokens) {
    const result = await deps.fcm.send(token, {
      title: row.title,
      body: row.body,
      data: { kind: row.kind, inboxId },
    });
    if (result === "ok") sent++;
    else if (result === "invalid_token") dead.push(token);
  }
  // A token Firebase says no longer exists is a phone that uninstalled the app.
  if (dead.length > 0) await deps.deleteTokens(dead);

  return {
    status: 200,
    body: { sent, total: tokens.length, removed: dead.length },
  };
}
