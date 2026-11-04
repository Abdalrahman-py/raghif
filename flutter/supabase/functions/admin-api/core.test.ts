// Run:  node --experimental-strip-types --test supabase/functions/admin-api/
// (Node 22.6+; also valid under Deno.) No network, no Supabase: every client
// is a recording fake.
import test from "node:test";
import assert from "node:assert/strict";
import { generatePin, GOVERNORATES, handle, isWeakPin, syntheticEmail } from "./core.ts";
import type { Deps, RpcResult } from "./core.ts";

const OWNER = "11111111-1111-1111-1111-111111111111";
const STORE = "22222222-2222-2222-2222-222222222222";
const USER = "33333333-3333-3333-3333-333333333333";

type Call = { who: "admin" | "me"; name: string; args?: Record<string, unknown> };

function harness(opts: {
  isAdmin?: boolean;
  gateError?: boolean;
  rpc?: Record<string, (args?: Record<string, unknown>) => RpcResult>;
  createUserError?: boolean;
  seq?: number[];
} = {}) {
  const calls: Call[] = [];
  const deleted: string[] = [];
  const created: unknown[] = [];
  const answer = (who: "admin" | "me") =>
  async (name: string, args?: Record<string, unknown>): Promise<RpcResult> => {
    calls.push({ who, name, args });
    if (who === "me" && name === "is_admin") {
      if (opts.gateError) return { data: null, error: { message: "boom" } };
      return { data: opts.isAdmin ?? true, error: null };
    }
    const custom = opts.rpc?.[name];
    if (custom) return custom(args);
    if (name === "check_availability") {
      return { data: [{ phone_exists: false, national_id_exists: false }], error: null };
    }
    if (name === "admin_create_store_for") return { data: { id: STORE }, error: null };
    if (name === "admin_revoke_sessions") return { data: 2, error: null };
    return { data: null, error: null };
  };
  let i = 0;
  const deps: Deps = {
    admin: {
      rpc: answer("admin"),
      auth: {
        admin: {
          createUser: (a) => {
            created.push(a);
            if (opts.createUserError) {
              return Promise.resolve({ data: { user: null }, error: { message: "exists" } });
            }
            return Promise.resolve({ data: { user: { id: OWNER } }, error: null });
          },
          deleteUser: (id) => {
            deleted.push(id);
            return Promise.resolve({});
          },
        },
      },
    },
    asUser: () => ({ rpc: answer("me") }),
    // Deterministic digits: 7,3,1,9, then repeats (a fine PIN: 7319).
    randomInt: (max) => {
      const seq = opts.seq ?? [7, 3, 1, 9];
      return seq[i++ % seq.length] % max;
    },
  };
  return { deps, calls, deleted, created };
}

const authed = { get: (n: string) => (n === "authorization" ? "Bearer tok" : null) };
const anon = { get: () => null };

const bakery = {
  action: "create-bakery",
  ownerName: "أبو أحمد",
  phone: "0599123456",
  nationalId: "912345678",
  storeName: "مخبز الأمل",
  area: "الرمال",
  governorate: "غزة",
};

test("PIN rules: weak PINs are refused, generator never returns one", () => {
  for (const p of ["0000", "1111", "9999", "1234", "4321", "0123", "9876"]) {
    assert.equal(isWeakPin(p), true, p);
  }
  for (const p of ["7319", "2580", "1357", "1243"]) assert.equal(isWeakPin(p), false, p);
  // A hostile RNG that keeps proposing 1234 then 0000 must still end on a good PIN.
  const seq = [1, 2, 3, 4, 0, 0, 0, 0, 5, 9, 2, 6];
  let i = 0;
  const pin = generatePin((m) => seq[i++ % seq.length] % m);
  assert.equal(pin, "5926");
  assert.match(pin, /^\d{4}$/);
});

test("synthetic email matches the auth gateway's", () => {
  assert.equal(syntheticEmail("912345678"), "nid-912345678@raghif.internal");
  assert.equal(syntheticEmail("9-12 3"), "nid-9123@raghif.internal");
});

test("a request without a token is 401 and touches nothing", async () => {
  const h = harness();
  const r = await handle(anon, { action: "create-bakery" }, h.deps);
  assert.equal(r.status, 401);
  assert.equal(h.calls.length, 0);
});

test("a non-administrator is 403 and nothing runs with the service key", async () => {
  const h = harness({ isAdmin: false });
  const r = await handle(authed, bakery, h.deps);
  assert.equal(r.status, 403);
  assert.equal(h.calls.filter((c) => c.who === "admin").length, 0);
  assert.equal(h.created.length, 0);
});

test("an error from the admin check fails closed", async () => {
  const h = harness({ gateError: true });
  const r = await handle(authed, bakery, h.deps);
  assert.equal(r.status, 403);
});

test("unknown action is 400", async () => {
  const r = await handle(authed, { action: "drop-everything" }, harness().deps);
  assert.equal(r.status, 400);
});

test("create-bakery: owner profile + store, PIN returned once", async () => {
  const h = harness();
  const r = await handle(authed, bakery, h.deps);
  assert.equal(r.status, 200);
  assert.equal(r.body.ok, true);
  assert.equal(r.body.userId, OWNER);
  assert.equal(r.body.storeId, STORE);
  assert.equal(r.body.pin, "7319");
  const profile = h.calls.find((c) => c.name === "create_profile")!;
  assert.equal(profile.args!.p_role, "owner");
  assert.equal(profile.args!.p_verification_status, "verified");
  assert.equal(profile.args!.p_pin, "7319");
  assert.equal(profile.args!.p_phone, "0599123456");
  const store = h.calls.find((c) => c.name === "admin_create_store_for")!;
  assert.equal(store.args!.p_owner, OWNER);
  assert.equal(store.args!.p_bag_price, 3);
  assert.equal(store.args!.p_daily_bag_limit, 100);
  assert.equal(h.deleted.length, 0);
  assert.deepEqual(h.created[0], {
    email: "nid-912345678@raghif.internal",
    email_confirm: true,
    user_metadata: { national_id: "912345678" },
  });
});

test("create-bakery validates its input before creating anything", async () => {
  const bad: Array<[string, Record<string, unknown>]> = [
    ["phone", { phone: "123" }],
    ["nationalId", { nationalId: "12" }],
    ["governorate", { governorate: "الشمال" }],
    ["storeName", { storeName: "  " }],
    ["ownerName", { ownerName: "" }],
    ["price", { bagPrice: -1 }],
    ["limit", { dailyBagLimit: 1.5 }],
    ["batch", { batchSize: 0 }],
  ];
  for (const [label, patch] of bad) {
    const h = harness();
    const r = await handle(authed, { ...bakery, ...patch }, h.deps);
    assert.equal(r.status, 400, label);
    assert.equal(h.created.length, 0, label);
  }
  assert.ok(GOVERNORATES.includes("غزة"));
});

test("create-bakery: a taken phone or national id is 409, no user created", async () => {
  for (const flags of [
    { phone_exists: true, national_id_exists: false },
    { phone_exists: false, national_id_exists: true },
  ]) {
    const h = harness({ rpc: { check_availability: () => ({ data: [flags], error: null }) } });
    const r = await handle(authed, bakery, h.deps);
    assert.equal(r.status, 409);
    assert.equal(h.created.length, 0);
  }
});

test("create-bakery: if the store fails, the auth user is removed and no PIN leaks", async () => {
  const h = harness({
    rpc: { admin_create_store_for: () => ({ data: null, error: { message: "owner already has a store" } }) },
  });
  const r = await handle(authed, bakery, h.deps);
  assert.equal(r.status, 500);
  assert.deepEqual(h.deleted, [OWNER]);
  assert.equal(JSON.stringify(r.body).includes("7319"), false);
  assert.equal(r.body.pin, undefined);
});

test("create-bakery: a failed auth user creation is 500 and deletes nothing", async () => {
  const h = harness({ createUserError: true });
  const r = await handle(authed, bakery, h.deps);
  assert.equal(r.status, 500);
  assert.equal(h.deleted.length, 0);
});

test("reset-pin: sets a fresh PIN, signs the user out, returns the PIN once", async () => {
  const h = harness();
  const r = await handle(authed, { action: "reset-pin", userId: USER }, h.deps);
  assert.equal(r.status, 200);
  assert.equal(r.body.pin, "7319");
  const names = h.calls.filter((c) => c.who === "admin").map((c) => c.name);
  assert.deepEqual(names, ["admin_set_pin", "admin_revoke_sessions"]);
});

test("reset-pin: bad id 400, unknown user 404, administrator 403", async () => {
  assert.equal((await handle(authed, { action: "reset-pin", userId: "x" }, harness().deps)).status, 400);
  const nf = harness({ rpc: { admin_set_pin: () => ({ data: null, error: { message: "user not found" } }) } });
  assert.equal((await handle(authed, { action: "reset-pin", userId: USER }, nf.deps)).status, 404);
  const ad = harness({ rpc: { admin_set_pin: () => ({ data: null, error: { message: "cannot reset an administrator PIN" } }) } });
  const r = await handle(authed, { action: "reset-pin", userId: USER }, ad.deps);
  assert.equal(r.status, 403);
  assert.equal(ad.calls.some((c) => c.name === "admin_revoke_sessions"), false);
});

test("set-store-status: goes through the caller's identity; archiving signs the owner out", async () => {
  const h = harness({
    rpc: { admin_set_store_status: () => ({ data: { id: STORE, owner_id: OWNER, status: "archived" }, error: null }) },
  });
  const r = await handle(authed, { action: "set-store-status", storeId: STORE, status: "archived" }, h.deps);
  assert.equal(r.status, 200);
  assert.equal(r.body.sessionsRevoked, 2);
  const change = h.calls.find((c) => c.name === "admin_set_store_status")!;
  assert.equal(change.who, "me");
  const revoke = h.calls.find((c) => c.name === "admin_revoke_sessions")!;
  assert.equal(revoke.who, "admin");
  assert.equal(revoke.args!.p_user, OWNER);
});

test("set-store-status: pausing does not sign anyone out; bad input is 400", async () => {
  const h = harness({
    rpc: { admin_set_store_status: () => ({ data: { id: STORE, owner_id: OWNER, status: "paused" }, error: null }) },
  });
  const r = await handle(authed, { action: "set-store-status", storeId: STORE, status: "paused" }, h.deps);
  assert.equal(r.status, 200);
  assert.equal(h.calls.some((c) => c.name === "admin_revoke_sessions"), false);
  assert.equal((await handle(authed, { action: "set-store-status", storeId: STORE, status: "deleted" }, harness().deps)).status, 400);
  assert.equal((await handle(authed, { action: "set-store-status", storeId: "nope", status: "active" }, harness().deps)).status, 400);
});

test("set-store-status: an unknown store is 404", async () => {
  const h = harness({ rpc: { admin_set_store_status: () => ({ data: null, error: { message: "store not found" } }) } });
  const r = await handle(authed, { action: "set-store-status", storeId: STORE, status: "paused" }, h.deps);
  assert.equal(r.status, 404);
});

test("set-account-status: disabling signs the user out, re-enabling does not", async () => {
  const prof = { id: USER, account_status: "disabled" };
  const off = harness({ rpc: { admin_set_buyer_status: () => ({ data: prof, error: null }) } });
  const r1 = await handle(authed, { action: "set-account-status", userId: USER, status: "disabled" }, off.deps);
  assert.equal(r1.status, 200);
  assert.equal(off.calls.some((c) => c.name === "admin_revoke_sessions"), true);

  const on = harness({ rpc: { admin_set_buyer_status: () => ({ data: { ...prof, account_status: "active" }, error: null }) } });
  const r2 = await handle(authed, { action: "set-account-status", userId: USER, status: "active" }, on.deps);
  assert.equal(r2.status, 200);
  assert.equal(on.calls.some((c) => c.name === "admin_revoke_sessions"), false);
});

test("set-account-status: a refusal from the database becomes 400", async () => {
  const h = harness({ rpc: { admin_set_buyer_status: () => ({ data: null, error: { message: "an administrator cannot be disabled here" } }) } });
  const r = await handle(authed, { action: "set-account-status", userId: USER, status: "disabled" }, h.deps);
  assert.equal(r.status, 400);
  assert.equal(h.calls.some((c) => c.name === "admin_revoke_sessions"), false);
});
