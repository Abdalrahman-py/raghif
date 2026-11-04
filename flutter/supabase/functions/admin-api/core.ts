// Logic of the admin-api edge function, with every outside thing injected so
// it can be tested without Deno or a network. index.ts wires the real clients.
//
// Why this function exists: creating an auth user and resetting a PIN need the
// service key, which must never reach the admin panel's browser. The panel
// sends its signed-in administrator's JWT here; we confirm it belongs to an
// administrator (is_admin()), and only then use the service key.
//
// Everything the administrator can do WITHOUT the service key (stats, lists,
// editing a bakery, verification, announcements) the panel calls straight on
// the admin_* RPCs, which guard themselves.
//
// PINs are generated here and returned once in the response. They are never
// logged and never stored in plain text (only the bcrypt hash, in Postgres).

export interface RpcResult {
  data: unknown;
  error: { message: string } | null;
}

export interface Rpc {
  rpc(name: string, args?: Record<string, unknown>): Promise<RpcResult>;
}

export interface AdminClient extends Rpc {
  auth: {
    admin: {
      createUser(args: {
        email: string;
        email_confirm: boolean;
        user_metadata: Record<string, unknown>;
      }): Promise<{
        data: { user: { id: string } | null };
        error: { message: string } | null;
      }>;
      deleteUser(id: string): Promise<unknown>;
    };
  };
}

export interface Deps {
  /** Service-role client. */
  admin: AdminClient;
  /** A client that acts as the caller, using their JWT. */
  asUser: (jwt: string) => Rpc;
  /** Uniform random integer in [0, max). */
  randomInt: (max: number) => number;
}

export interface Reply {
  status: number;
  body: Record<string, unknown>;
}

export const GOVERNORATES = ["شمال غزة", "غزة", "الوسطى", "خانيونس", "رفح"];

const WEAK_PINS = new Set([
  "0123", "1234", "2345", "3456", "4567", "5678", "6789",
  "3210", "4321", "5432", "6543", "7654", "8765", "9876",
]);

/** Same rule as public.change_my_pin: no repeated digit, no plain run. */
export function isWeakPin(pin: string): boolean {
  return /^(\d)\1{3}$/.test(pin) || WEAK_PINS.has(pin);
}

export function generatePin(randomInt: (max: number) => number): string {
  for (;;) {
    let pin = "";
    for (let i = 0; i < 4; i++) pin += String(randomInt(10));
    if (!isWeakPin(pin)) return pin;
  }
}

/** Must match auth-gateway's syntheticEmail so the owner can sign in later. */
export function syntheticEmail(nationalId: string): string {
  return `nid-${nationalId.replace(/[^a-zA-Z0-9]/g, "")}@raghif.internal`;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function fail(status: number, error: string): Reply {
  return { status, body: { error } };
}

function text(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function bearer(header: string | null): string | null {
  const m = /^Bearer\s+(.+)$/i.exec(header ?? "");
  return m ? m[1] : null;
}

export async function handle(
  headers: { get(name: string): string | null },
  // deno-lint-ignore no-explicit-any
  body: any,
  deps: Deps,
): Promise<Reply> {
  const jwt = bearer(headers.get("authorization"));
  if (!jwt) return fail(401, "missing token");

  const me = deps.asUser(jwt);
  const gate = await me.rpc("is_admin");
  if (gate.error || gate.data !== true) return fail(403, "not authorized");

  try {
    switch (body?.action) {
      case "create-bakery":
        return await createBakery(body, deps);
      case "reset-pin":
        return await resetPin(body, deps);
      case "set-store-status":
        return await setStoreStatus(body, me, deps);
      case "set-account-status":
        return await setAccountStatus(body, me, deps);
      default:
        return fail(400, "unknown action");
    }
  } catch (e) {
    // Never echo internals (or anything that could contain a PIN).
    console.error("admin-api failure:", (e as Error).message);
    return fail(500, "internal error");
  }
}

// ----------------------------------------------------------------- actions --

async function createBakery(
  // deno-lint-ignore no-explicit-any
  b: any,
  deps: Deps,
): Promise<Reply> {
  const ownerName = text(b.ownerName);
  const phone = text(b.phone);
  const nationalId = text(b.nationalId);
  const storeName = text(b.storeName);
  const area = text(b.area);
  const governorate = text(b.governorate);
  const dailyBagLimit = b.dailyBagLimit == null ? 100 : Number(b.dailyBagLimit);
  const bagPrice = b.bagPrice == null ? 3 : Number(b.bagPrice);
  const batchSize = b.batchSize == null ? 10 : Number(b.batchSize);

  if (!ownerName) return fail(400, "ownerName required");
  if (!/^0\d{9}$/.test(phone)) return fail(400, "phone must be 10 digits starting with 0");
  if (!/^\d{9}$/.test(nationalId)) return fail(400, "nationalId must be 9 digits");
  if (!storeName) return fail(400, "storeName required");
  if (!GOVERNORATES.includes(governorate)) return fail(400, "invalid governorate");
  if (!Number.isInteger(dailyBagLimit) || dailyBagLimit < 0) return fail(400, "invalid dailyBagLimit");
  if (!Number.isFinite(bagPrice) || bagPrice < 0) return fail(400, "invalid bagPrice");
  if (!Number.isInteger(batchSize) || batchSize < 1) return fail(400, "invalid batchSize");

  const avail = await deps.admin.rpc("check_availability", {
    p_phone: phone,
    p_national_id: nationalId,
  });
  if (avail.error) throw new Error(avail.error.message);
  const row = Array.isArray(avail.data) ? avail.data[0] : avail.data;
  // deno-lint-ignore no-explicit-any
  const r = row as any;
  if (r?.phone_exists) return fail(409, "phone already registered");
  if (r?.national_id_exists) return fail(409, "national id already registered");

  const { data: created, error: createError } = await deps.admin.auth.admin
    .createUser({
      email: syntheticEmail(nationalId),
      email_confirm: true,
      user_metadata: { national_id: nationalId },
    });
  if (createError || !created?.user) {
    throw new Error(createError?.message ?? "could not create the account");
  }
  const userId = created.user.id;

  try {
    const pin = generatePin(deps.randomInt);
    const profile = await deps.admin.rpc("create_profile", {
      p_id: userId,
      p_phone: phone,
      p_national_id: nationalId,
      p_pin: pin,
      p_name: ownerName,
      p_jawwal_pay_number: null,
      p_role: "owner",
      p_verification_status: "verified",
    });
    if (profile.error) throw new Error(profile.error.message);

    const store = await deps.admin.rpc("admin_create_store_for", {
      p_owner: userId,
      p_name: storeName,
      p_area: area || null,
      p_governorate: governorate,
      p_daily_bag_limit: dailyBagLimit,
      p_bag_price: bagPrice,
      p_batch_size: batchSize,
    });
    if (store.error) throw new Error(store.error.message);

    // deno-lint-ignore no-explicit-any
    const storeId = (store.data as any)?.id ?? null;
    return { status: 200, body: { ok: true, userId, storeId, pin } };
  } catch (e) {
    // Nothing was committed for the store, so removing the auth user (the
    // profile cascades with it) lets the administrator simply retry.
    await deps.admin.auth.admin.deleteUser(userId);
    throw e;
  }
}

async function resetPin(
  // deno-lint-ignore no-explicit-any
  b: any,
  deps: Deps,
): Promise<Reply> {
  const userId = text(b.userId);
  if (!UUID.test(userId)) return fail(400, "invalid userId");

  const pin = generatePin(deps.randomInt);
  const set = await deps.admin.rpc("admin_set_pin", { p_user: userId, p_pin: pin });
  if (set.error) {
    if (/not found/.test(set.error.message)) return fail(404, "user not found");
    if (/administrator/.test(set.error.message)) return fail(403, "cannot reset an administrator");
    throw new Error(set.error.message);
  }
  // A forgotten PIN may be a lost phone: sign the user out everywhere.
  await deps.admin.rpc("admin_revoke_sessions", { p_user: userId });
  return { status: 200, body: { ok: true, pin } };
}

async function setStoreStatus(
  // deno-lint-ignore no-explicit-any
  b: any,
  me: Rpc,
  deps: Deps,
): Promise<Reply> {
  const storeId = text(b.storeId);
  const status = text(b.status);
  if (!UUID.test(storeId)) return fail(400, "invalid storeId");
  if (!["active", "paused", "archived"].includes(status)) {
    return fail(400, "invalid status");
  }
  // As the caller, so the SQL guard (is_admin) is what authorizes the change.
  const res = await me.rpc("admin_set_store_status", {
    p_store: storeId,
    p_status: status,
  });
  if (res.error) {
    if (/not found/.test(res.error.message)) return fail(404, "store not found");
    return fail(400, res.error.message);
  }
  // deno-lint-ignore no-explicit-any
  const store = res.data as any;
  let sessionsRevoked = 0;
  if (status === "archived" && store?.owner_id) {
    const r = await deps.admin.rpc("admin_revoke_sessions", { p_user: store.owner_id });
    sessionsRevoked = Number(r.data ?? 0);
  }
  return { status: 200, body: { ok: true, store, sessionsRevoked } };
}

async function setAccountStatus(
  // deno-lint-ignore no-explicit-any
  b: any,
  me: Rpc,
  deps: Deps,
): Promise<Reply> {
  const userId = text(b.userId);
  const status = text(b.status);
  if (!UUID.test(userId)) return fail(400, "invalid userId");
  if (!["active", "disabled"].includes(status)) return fail(400, "invalid status");
  const res = await me.rpc("admin_set_buyer_status", {
    p_user: userId,
    p_status: status,
  });
  if (res.error) {
    if (/not found/.test(res.error.message)) return fail(404, "user not found");
    return fail(400, res.error.message);
  }
  let sessionsRevoked = 0;
  if (status === "disabled") {
    const r = await deps.admin.rpc("admin_revoke_sessions", { p_user: userId });
    sessionsRevoked = Number(r.data ?? 0);
  }
  return { status: 200, body: { ok: true, profile: res.data, sessionsRevoked } };
}
