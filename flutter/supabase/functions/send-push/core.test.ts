// Run:  node --experimental-strip-types --test supabase/functions/send-push/
import test from "node:test";
import assert from "node:assert/strict";
import { handle, safeEqual } from "./core.ts";
import type { Deps, SendResult } from "./core.ts";

const ID = "44444444-4444-4444-4444-444444444444";
const SECRET = "s3cret-value";
const good = { get: (n: string) => (n === "x-notify-batch-secret" ? SECRET : null) };

function harness(over: Partial<{
  secret: string | undefined;
  row: { user_id: string; title: string; body: string; kind: string } | null;
  tokens: string[];
  configured: boolean;
  results: Record<string, SendResult>;
}> = {}) {
  const sent: Array<{ token: string; message: unknown }> = [];
  const deleted: string[][] = [];
  const o = {
    secret: SECRET,
    row: { user_id: "u1", title: "عنوان", body: "نص", kind: "announcement" },
    tokens: ["t1", "t2"],
    configured: true,
    results: {} as Record<string, SendResult>,
    ...over,
  };
  const deps: Deps = {
    secret: o.secret,
    loadInbox: () => Promise.resolve(o.row),
    loadTokens: () => Promise.resolve(o.tokens),
    deleteTokens: (t) => {
      deleted.push(t);
      return Promise.resolve();
    },
    fcm: {
      configured: o.configured,
      send: (token, message) => {
        sent.push({ token, message });
        return Promise.resolve(o.results[token] ?? "ok");
      },
    },
  };
  return { deps, sent, deleted };
}

test("safeEqual", () => {
  assert.equal(safeEqual("abc", "abc"), true);
  assert.equal(safeEqual("abc", "abd"), false);
  assert.equal(safeEqual("abc", "abcd"), false);
  assert.equal(safeEqual("", ""), true);
});

test("an unset secret refuses everything (fails closed)", async () => {
  const h = harness({ secret: undefined });
  assert.equal((await handle(good, { inboxId: ID }, h.deps)).status, 503);
  assert.equal(h.sent.length, 0);
});

test("a missing or wrong secret is 401", async () => {
  const h = harness();
  assert.equal((await handle({ get: () => null }, { inboxId: ID }, h.deps)).status, 401);
  assert.equal((await handle({ get: () => "nope" }, { inboxId: ID }, h.deps)).status, 401);
  assert.equal(h.sent.length, 0);
});

test("a bad body is 400", async () => {
  const h = harness();
  assert.equal((await handle(good, {}, h.deps)).status, 400);
  assert.equal((await handle(good, { inboxId: "x" }, h.deps)).status, 400);
  assert.equal((await handle(good, null, h.deps)).status, 400);
});

test("sends the inbox row to every device of its owner", async () => {
  const h = harness();
  const r = await handle(good, { inboxId: ID }, h.deps);
  assert.equal(r.status, 200);
  assert.deepEqual(r.body, { sent: 2, total: 2, removed: 0 });
  assert.deepEqual(h.sent.map((s) => s.token), ["t1", "t2"]);
  assert.deepEqual(h.sent[0].message, {
    title: "عنوان",
    body: "نص",
    data: { kind: "announcement", inboxId: ID },
  });
  assert.equal(h.deleted.length, 0);
});

test("an unknown notification sends nothing", async () => {
  const h = harness({ row: null });
  const r = await handle(good, { inboxId: ID }, h.deps);
  assert.equal(r.status, 200);
  assert.equal(r.body.sent, 0);
  assert.equal(h.sent.length, 0);
});

test("a user with no devices sends nothing", async () => {
  const h = harness({ tokens: [] });
  const r = await handle(good, { inboxId: ID }, h.deps);
  assert.equal(r.body.sent, 0);
  assert.equal(h.sent.length, 0);
});

test("without FCM configured it degrades to sent:0, not an error", async () => {
  const h = harness({ configured: false });
  const r = await handle(good, { inboxId: ID }, h.deps);
  assert.equal(r.status, 200);
  assert.equal(r.body.sent, 0);
  assert.equal(h.sent.length, 0);
});

test("tokens Firebase rejects as gone are deleted; transient errors are kept", async () => {
  const h = harness({
    tokens: ["ok", "gone", "flaky"],
    results: { gone: "invalid_token", flaky: "error" },
  });
  const r = await handle(good, { inboxId: ID }, h.deps);
  assert.deepEqual(r.body, { sent: 1, total: 3, removed: 1 });
  assert.deepEqual(h.deleted, [["gone"]]);
});
