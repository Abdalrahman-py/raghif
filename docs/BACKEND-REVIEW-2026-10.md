# Backend and logic review — 2026-10-07

Scope: everything except UI — Postgres schema, RLS, RPCs, Edge Functions,
repositories, auth, notifications, tests, CI, dependencies, project docs. The
UI is being redesigned and was not reviewed.

Method: read every migration, both Edge Functions, both repositories, the
tests, CI and the spec kit; assumed nothing was correct because it was
documented as correct. **Nothing here was executed** — no Postgres, Flutter or
Deno in the review environment. CI (`analyze`, `test`, and the new `sql` job)
is the first real run of the changes in this PR.

Severity: **Critical** = someone can act as another user or defeat a core
rule. **High** = wrong results or data loss under realistic conditions.
**Medium** = weakens safety or maintainability. Status: **Fixed** (this PR),
**Open** (tracked in TASKS.md), **Decision** (needs the owner).

## Findings

| ID | Sev | Finding | Status |
|---|---|---|---|
| R-01 | Critical | `auth-gateway` `otp-confirm` accepted the constant `4821` for any national ID and returned a real session. Anyone who knows (or guesses) an ID could sign in as that person — including a store owner. National IDs are not secret. | **Fixed** — mock OTP is off unless `ALLOW_MOCK_OTP=true`; set it only on demo/staging projects. **Deploy note:** until set, the app's default OTP login returns 403; PIN login is unaffected. |
| R-02 | Critical | PIN login had no attempt limit: a 4-digit PIN falls to 10,000 requests. | **Fixed** — 5 misses lock the profile 15 min (`verify_pin_and_get_profile`), counters unreadable by the app, constant-ish time for unknown IDs. Side effect: an attacker can lock a victim out (see R-12). |
| R-03 | Critical | `seed-demo` creates accounts with the public PIN `1234`, including a store **owner**. Guarded only by one secret. If it was ever run against the live project, those accounts exist. | **Open** (P0-1): verify they do not exist in prod; make seeding refuse when real profiles exist or when `ENVIRONMENT=production`. |
| R-04 | High | `reserve_bag` trusted the client's date. `UNIQUE (user_id, purchase_date)` only means "one bag per day" if the set of days is bounded; a modified client could take one bag per invented date. A wrong phone clock booked the wrong day silently. | **Fixed** — date must be today or tomorrow in `Asia/Gaza` by server clock. |
| R-05 | High | RLS let a store owner `UPDATE stores` directly (set `bags_remaining`, bypassing `save_store_allocation` and its lock) and `DELETE` the store, cascading every purchase. | **Fixed** — direct insert/update/delete on `stores` revoked and policies dropped; RPC only. |
| R-06 | High | `reserve_bag` was not idempotent. Network drops the *response*, the buyer retries, gets "already reserved a bag today" — about a reservation they hold. | **Fixed** — same-store retry returns the existing purchase. The app's error mapping still needs to distinguish rule errors (R-25). |
| R-07 | High | `profiles.verification_status` is writable by the user, and `reserve_bag` never checks it. The simulated Jawwal Pay step is therefore decorative, and "verified" proves nothing. | **Decision** (D-1): either verification is meaningless until Jawwal Pay is real (say so; drop the column from the buy path), or the mock flips it through a server RPC and `reserve_bag` requires it. |
| R-08 | High | `stores.bags_remaining` is one counter, but buyers may pre-order for tomorrow. Today's and tomorrow's reservations draw on the same pool, and the daily reset exists only as a side effect of the owner re-saving the allocation. | **Open** (P0-2): per-(store, date) allocation table (`store_days`), `reserve_bag` locks and decrements that row. Needs a spec ruling on rollover (D-2). |
| R-09 | High | Push is fire-and-forget: `pg_net` POST → function → one FCM call per token, sequentially, a fresh OAuth exchange each time. No retry, no delivery record, dead tokens never pruned, no way to tell the owner a batch was not reached. | **Open** (P1-1): outbox table + worker, parallel sends, prune `UNREGISTERED` tokens, cache the access token. |
| R-10 | Medium | Both trigger migrations hard-code the production project URL. No staging project, no local `supabase start`, and the history cannot be replayed elsewhere. | **Open** (P1-2): read the base URL from Vault/config. |
| R-11 | Medium | `check-availability` is unauthenticated and answers "is this phone / national ID registered" — an enumeration oracle for a population list. | **Open** (P1-3): rate-limit, or fold the check into `register` and return a uniform error. |
| R-12 | Medium | 4-digit PINs are weak by construction; the lockout (R-02) caps online guessing but enables targeted lock-out of a specific person. | **Decision** (D-3): accept for the pilot (on-site help), or move to 6 digits / add an owner-assisted unlock. |
| R-13 | Medium | No path for a bag that is never collected: "no cancellations" is a rule, but nothing closes the day, so uncollected bags stay `waiting`/`notified` forever and the counts depend on the owner. | **Decision** (D-4): define end-of-day (auto-expire to a `missed` status? owner "close day" RPC?). |
| R-14 | Medium | `scan_events` stores the scanned national ID in clear text, indefinitely, though `purchase_id` already identifies the person for the store owner. | **Open** (P1-4): drop the column or hash it; set retention. |
| R-15 | Medium | `notify_next_batch` / `collect_purchase` accept any `purchase_date`, so an owner action can touch old days. | **Open** (P2-2): bound to the Gaza date window. |
| R-16 | Medium | Realtime subscribes to all of `purchases` and `stores`; every change re-runs every live query on every connected device. Fine for one store, a battery and bandwidth problem at ten. | **Open** (P2-3): filter by `store_id`; debounce re-queries. |
| R-17 | Medium | 31 migrations with fix-forward corrections (e.g. `fix_pgcrypto_schema_refs`, two `fix_rls_perf_*`); the current definition of any function requires reading several files. | **Open** (P1-8): generate a schema snapshot and RPC catalogue; keep migrations append-only. |
| R-18 | Medium | CI ran no SQL tests (they needed Docker by hand), no Edge Function check, no coverage report; analyzer is `flutter_lints` only. | **Fixed** (SQL job added). **Open** (P2-1): `deno check`/`deno lint`, stricter analyzer (`strict-casts`, `strict-inference`, `strict-raw-types`), coverage threshold on `data/` and `domain/`. |
| R-19 | Medium | Edge Function returned internal error text (`err.message`) on any 500, including Auth admin messages. | **Fixed** — generic message to the caller, details to logs. |
| R-20 | Medium | No observability: no structured logs, no alert on repeated failed logins, push failures or sold-out races. | **Open** (P2-4). |
| R-21 | Medium | No backup/restore or incident procedure for a database holding national IDs and phone numbers for a population at risk. | **Open** (P1-5): confirm PITR, write a one-page runbook (who, what, how to revoke sessions). |
| R-22 | Low | Dead code and dependencies: `core/auth/pin_hash.dart` (client-side hashing, unused), and `crypto`, `freezed*`, `json_*`, `intl`, `easy_localization`, `build_runner` — none imported anywhere. Contradicts constitution IX. | **Fixed**. |
| R-23 | Low | Stale documents contradicted the code (spec said `drift` cache, "Bilingual", SMS, owner "hardcoded by phone"; README said bilingual EN; migration plan described a drift app; a demo-accounts file said "seed the local database"). | **Fixed** (spec rewritten, README/plan/comments corrected). |
| R-24 | Low | `fcm_service` registers tokens by direct upsert; a token moving between users depends on RLS shape not documented anywhere. | **Open** (P2-5): move to an RPC with ownership rules, delete on sign-out. |
| R-25 | Low | `SupabaseQueueRepository.mapRpcError` types only "sold out"; "already reserved", "invalid purchase date", "not the store owner" all surface as *backend unavailable*, so the UI tells a rule-violating buyer the network is down. | **Open** (P0-3): typed exceptions per rule error. UI wording waits for the redesign. |
| R-26 | High | The pickup receipt is a **client-minted, unsigned JSON QR** carrying the buyer's name and national ID. A screenshot leaks both; anyone holding the image can present it; the owner's phone validates it against its own copy of the queue, not against the server. The code's own header comment already lists this as the production roadmap. | **Open** (P0-4): server-issued opaque, expiring, single-use redemption token; `redeem_receipt(token)` RPC marks collected atomically and returns the name/ID only at redemption; delete client-side QR minting. |

## Things that are good and should be kept

- Postgres decides: RLS on every table, RPCs authorize their own caller,
  service-role work stays in Edge Functions, `pin_hash` never reaches a client.
- `lock_direct_writes` and its SQL tests — the right instinct; now in CI.
- Shared-secret auth on the push relay, secret in Vault, fail-closed.
- Writes that fail loudly; receipt-only offline exception.
- The constitution itself: short, enforceable, and it caught real drift.

## Decisions needed from the owner

| # | Question | Default if undecided |
|---|---|---|
| D-1 | Is `verification_status` enforced before buying, or cosmetic until Jawwal Pay is real? | Cosmetic; documented as such in spec §10. |
| D-2 | Does an unsold allocation roll to the next day? Is the daily limit reset by the owner or automatic? | Owner sets each day; no rollover. |
| D-3 | 4-digit PIN with lockout for the pilot, or 6 digits? | 4 digits + lockout, owner-assisted unlock out of band. |
| D-4 | What happens to bags not collected by closing time? | Stay as-is; owner reads `not_collected` in the daily summary. |
| D-5 | Is the notification channel push (built) or SMS (specced)? | Push; SMS deferred until a gateway exists. |
