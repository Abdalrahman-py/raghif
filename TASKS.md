# Raghif — Task Backlog

Open GitHub issues (prioritized p0 > p1 > p2) are the main task queue; this file
holds broader work that isn't issue-shaped. IDs (`P0-1`…) are referenced from
[docs/BACKEND-REVIEW-2026-10.md](docs/BACKEND-REVIEW-2026-10.md) and `spec.md`.
One item at a time, top to bottom within a priority.

## Working agreement (binding — constitution VII, VIII)

- Work on **feature branches only**, branched off `master`. Small, reviewable
  commits. Never push to `master`, never merge into it locally; `master`
  changes only through reviewed PRs. Merge/rebase `master` into your branch
  when it moves.
- Every PR passes CI (`.github/workflows/ci.yml`): `flutter analyze`,
  `flutter test`, and the SQL tests (`flutter/supabase/tests/run.sh`). The APK
  is built once per merge to `master` (`release.yml`), not per PR.
- Log each completed task in `CHANGELOG.md` **before** its commit.
- Any rule change ships with a test that cites its requirement ID
  (`spec.md`), and updates `spec.md` in the same PR.
- Source of truth: `spec.md` (what and why), `constitution.md` (what may not
  be broken), `docs/ARCHITECTURE.md` (how), `UI_SPEC.md` (look).
- CI pins Flutter 3.41.6 (`environment.flutter` in `flutter/pubspec.yaml`).
  Before bumping, bump the Gradle wrapper to ≥ 8.14 and re-check AGP/Kotlin.

## P0 — before any real user

- [ ] **P0-0 Ship the hardening PR.** Apply migration
      `20261007210000_harden_reserve_stores_and_pin_login`, redeploy
      `auth-gateway`, and decide per project whether to set
      `ALLOW_MOCK_OTP=true` (demo/staging only). Confirm the `sql` CI job is
      green first. *(R-01, R-02, R-04, R-05, R-06, R-19)*
- [ ] **P0-1 Prove the live project holds no demo accounts.** Query for the national IDs
      in `DEMO_ACCOUNTS` and `DEMO_QUEUE_BUYERS`
      (`flutter/supabase/functions/auth-gateway/index.ts`); delete them if
      present. Make `seed-demo` refuse when the project has non-demo
      profiles or `ENVIRONMENT=production`. *(R-03)*
- [ ] **P0-2 Per-day allocation.** Replace the single `stores.bags_remaining`
      counter with a `(store_id, day)` allocation row that `reserve_bag` locks
      and decrements; resolve rollover first (D-2, Q-7). SQL tests for today vs
      tomorrow pools. *(R-08)*
- [ ] **P0-3 Typed repository errors.** Map each RPC refusal (`already reserved`,
      `invalid purchase date`, `not the store owner`, `batch not notified`) to
      its own exception in `SupabaseQueueRepository.mapRpcError`, with tests.
      Wording waits for the redesign. *(R-25)*
- [ ] **P0-4 Server-issued receipt.** `issue_receipt` / `redeem_receipt(token)`
      RPCs: opaque, expiring, single-use token; redemption atomically collects
      and returns identity at that moment. Delete client-side QR minting and
      PII in the payload; keep the version key. *(R-26, spec RCP-2)*

## P1 — before the pilot

- [ ] **P1-1 Push outbox.** `notifications_outbox` table written in the same
      transaction as the state change; a worker sends in parallel, retries with
      backoff, prunes `UNREGISTERED` tokens, caches the FCM access token, and
      records delivery. *(R-09)*
- [ ] **P1-2 No hard-coded project URL.** Triggers read the Functions base URL
      from Vault/config so staging and `supabase start` work. Then create a
      staging project. *(R-10)*
- [ ] **P1-3 Close the enumeration oracle.** Rate-limit or remove
      `check-availability`; return uniform errors from `register`. *(R-11)*
- [ ] **P1-4 Minimise `scan_events`.** Drop or hash `scanned_national_id`; define
      retention. *(R-14)*
- [ ] **P1-5 Runbook and backups.** Confirm point-in-time recovery; one page:
      who is on call, how to revoke all sessions, how to rotate the Vault secret
      and FCM key, how to restore. *(R-21, NFR-6)*
- [ ] **P1-6 Concurrency test.** SQL test that N parallel `reserve_bag` calls for
      the last bag produce exactly one purchase and never negative stock.
- [ ] **P1-7 Owner decisions → spec.** Record D-1…D-5 outcomes in `spec.md`
      (§12 → §11) and implement what they imply (verification enforcement,
      PIN length, end-of-day handling).
- [ ] **P1-8 Schema snapshot.** Generate `supabase/schema/current.sql` and an RPC
      catalogue check so reviewers read the current definition of each function,
      not 31+ migrations. Keep migrations append-only. *(R-17)*

## P2 — hygiene

- [ ] **P2-1 Stricter checks in CI.** `deno check` + `deno lint` for Edge
      Functions; analyzer `strict-casts`, `strict-inference`,
      `strict-raw-types`; coverage threshold on `lib/data` and `lib/domain`.
      *(R-18)*
- [ ] **P2-2 Bound owner actions to the Gaza date window** in
      `notify_next_batch` / `collect_purchase`. *(R-15)*
- [ ] **P2-3 Scope Realtime** to the user's store/purchases and debounce
      re-queries. *(R-16)*
- [ ] **P2-4 Observability.** Structured Edge Function logs; alert on repeated
      lockouts, push failures and sold-out bursts. *(R-20)*
- [ ] **P2-5 Device tokens via RPC** with ownership rules; delete on sign-out.
      *(R-24)*
- [ ] **P2-6 Remove the long "production roadmap" comment** in
      `features/queue/qr_payload.dart` once P0-4 lands; it is captured in
      `spec.md` RCP-2.

## Done

- [x] Scaffold `flutter/`, project structure, design tokens as a Flutter theme.
- [x] Auth: phone/national ID + PIN, session persisted on device (now a Supabase
      session issued by the `auth-gateway` Edge Function).
- [x] Queue list / pre-order screens, owner dashboard, queue, history, customers.
- [x] Real data layer: every screen reads Postgres via repositories (Sep 2026
      refactor; #7, #8 closed).
- [x] Store-owner QR redemption scanner (#28, shipped in #39).
- [x] CI: analyze + test on PRs; release APK on merge to `master`.
- [x] Supabase backend: schema, RLS, RPCs, Realtime, FCM push (Sep 2026).
- [x] Backend-only data: no local database; receipt-only cache (2026-10-03).
- [x] 2026-10-07 review and hardening PR (this file's P0-0 ships it).

## Standing rulings

Kept in `constitution.md` §Authority (Arabic-only; one bag per ID per day across
stores; Supabase as the only source of data; server-owned calendar). If this
file and the constitution disagree, the constitution wins.
