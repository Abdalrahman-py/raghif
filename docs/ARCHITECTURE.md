# Raghif — Architecture

Status: current as of 2026-10-07. Source of truth for *why the backend is
shaped the way it is*. What the product does is in [spec.md](../spec.md); the
rules that may not be broken are in [constitution.md](../constitution.md).

## 1. The shape in one picture

```
 Buyer phone ─┐                                   ┌─ Postgres (Supabase) ──────────────┐
              │  supabase_flutter                 │  tables + constraints + RLS        │
 Owner phone ─┼─ REST/RPC (JWT = auth.uid()) ────▶│  RPC functions (SECURITY DEFINER)  │
              │  Realtime (read-only changes) ◀───│  triggers ──pg_net──┐              │
              │                                   └─────────────────────┼──────────────┘
              │  FCM push                                             ▼
              └──────────────◀──────────────  Edge Function: notify-batch ──▶ FCM
              │
              └─ sign-in / register ──────────▶  Edge Function: auth-gateway ──▶ Supabase Auth (admin)
                                                  (service role; PIN checks via service-only RPCs)
```

Three places can hold logic. Each rule goes in the *most binding* place that can
express it.

| Layer | Holds | Why there |
|---|---|---|
| **Constraints, RLS, column grants** | Invariants: one bag per ID per day, `bags_remaining >= 0`, who can read which row, which columns the app may write | Cannot be skipped by any client, query or future code path |
| **Postgres functions (RPC)** | Multi-step rules over our own tables: reserve a bag, release a batch, collect, change allocation, owner aggregates | One transaction: lock, check, write, all-or-nothing, no network hop between the steps |
| **Edge Functions** | Anything needing a secret, a third party, or Supabase Auth admin: FCM delivery, minting sessions, (later) the SMS gateway and Jawwal Pay | Postgres should not hold the FCM key or call out synchronously |
| **Flutter client** | Presentation and UX affordances (disable a button, show a count) | Never enforcement |

## 2. "Business logic exists as SQL" — what that means here

It does **not** mean Edge Functions. It means ordinary **PostgreSQL functions
(PL/pgSQL) exposed as RPC**: the app calls `supabase.rpc('reserve_bag', …)`,
which runs inside the database, as one transaction, with `auth.uid()` taken
from the caller's JWT. The files are `flutter/supabase/migrations/*.sql`.

Why this and not an Edge Function that "does the logic":

1. **Atomicity.** Reserving a bag is: lock the store row → check open and
   remaining → check this buyer has no bag today → compute the batch → decrement
   → insert. In Postgres that is one transaction. In an Edge Function it is
   several network round trips, and two buyers racing for the last bag is
   exactly the failure this product must not have (constitution I–III).
2. **No bypass.** If the rule lived in a function, the table would still need
   to be writable by *someone*, and that path would exist. Here the tables
   reject direct writes (migration `20260930130626_lock_direct_writes` and
   `20261007210000_…`); the RPC is the only door.
3. **Identity is free.** `auth.uid()` and RLS already know who is calling.
4. **Latency and cost.** One hop on a bad network instead of two or three.

What it costs, honestly:

- PL/pgSQL is harder to read, debug and unit-test than TypeScript. Mitigation:
  SQL tests (`flutter/supabase/tests/`) run on every PR in CI against a
  disposable Postgres. Every RPC rule needs a test there.
- Logic is versioned as migrations, so the *current* definition of a function
  is spread over several files (e.g. `reserve_bag` was created in one migration
  and redefined in a later one). Mitigation: a `supabase/schema` snapshot (task P1-8 in TASKS.md) and
  the RPC catalogue in spec.md §9.
- It is Postgres-specific. That is accepted: constitution IX forbids designing
  for a second backend.

**Rule of thumb for new work:** if it only touches our tables → RPC. If it
needs a secret or talks to the outside world → Edge Function, triggered from
Postgres (`pg_net`) or called by the client. Never both for the same rule.

## 3. Authentication

Users sign in with national ID (or phone) + 4-digit PIN. Supabase Auth has no
such method, so the `auth-gateway` Edge Function bridges:

1. It verifies the PIN through `verify_pin_and_get_profile` (service-role-only
   RPC; bcrypt via pgcrypto; **5 misses lock the profile for 15 minutes**).
2. It mints a real Supabase session for a synthetic, never-mailed email
   (`nid-<id>@raghif.internal`) with `generateLink` + `verifyOtp`.
3. The app then holds an ordinary Supabase session, so `auth.uid()` and RLS work
   unchanged.

Mock OTP login (national ID + fixed code) exists for demos only and is
**disabled unless `ALLOW_MOCK_OTP=true`** — while enabled it is an
account-takeover switch (constitution VI).

Known weaknesses are tracked in
[BACKEND-REVIEW-2026-10.md](BACKEND-REVIEW-2026-10.md) (R-03, R-11, R-12).

## 4. Authorization model

| Actor | Can read | Can write |
|---|---|---|
| anon | `stores` | nothing (the gateway function runs as service role) |
| buyer (`authenticated`) | `stores`; own `profiles`, `purchases`, `store_pins` | own `profiles(name, jawwal_pay_number, verification_status)`, own `device_tokens`; everything else only via RPC |
| store owner (`authenticated` + `stores.owner_id`) | the above, plus `purchases` of their store and the `profiles` of those buyers (never `pin_hash`) | only via RPC: `notify_next_batch`, `collect_purchase`, `save_store_allocation`, `set_store_open`, `record_scan` |
| service role | everything | Edge Functions only; the key never ships in the app |

"Owner" is a property of the store (`stores.owner_id`), not of the profile's
`role`. Every owner RPC re-checks it itself.

## 5. Time

**The server decides what day it is**: `(now() at time zone 'Asia/Gaza')::date`.
The phone's date is a *request*, validated by `reserve_bag` to be today or
tomorrow. A wrong phone clock fails loudly (`invalid purchase date`) instead of
silently booking the wrong day, and a hand-crafted request cannot invent days to
collect more than one bag.

## 6. Failure model

- **Writes fail loudly.** No optimistic local writes (constitution II).
- **Writes are idempotent.** A client that did not see the answer retries; the
  retry returns the same purchase and takes no second bag. This is the normal
  case on unreliable connections, not an edge case.
- **Notifications are best-effort today.** A trigger posts to `notify-batch`
  via `pg_net`, fire-and-forget; a lost push is not retried or recorded
  (R-09). The queue screen is the source of truth; the push is a nudge.
- **Reads show nothing new rather than something stale**, except the saved
  receipt, so the pickup QR opens offline.

## 7. Environments, secrets and migrations

- Secrets: `.env` (anon key only, gitignored) for the app; Supabase secrets for
  Edge Functions (`FCM_SERVICE_ACCOUNT`, `NOTIFY_BATCH_SECRET`,
  `SEED_DEMO_SECRET`, `ALLOW_MOCK_OTP`); the shared push secret lives in Vault.
- One Supabase project exists today and holds real pilot configuration. The
  trigger migrations hard-code its URL (R-10), so a staging project is not yet
  possible without editing history. Fixing this comes before any second
  environment.
- Never edit an applied migration; add a new one. Name migrations for what they
  change. Every migration that changes a rule adds or updates a SQL test.

## 8. What is deliberately not here

No second backend, no payments provider, no multi-language layer, no local
database (constitution I, IX). The Jawwal Pay and SMS integrations are
simulated and say so on screen (constitution VI).
