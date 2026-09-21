# Supabase Migration Plan

Decision (2026-09-19, repo owner): move Raghif from a local-only prototype to
a live Supabase backend (Postgres + Realtime + Auth + Edge Functions), with
the on-device `drift` database kept **permanently** as an offline cache/read
layer. This supersedes the 2026-09-06 "never add Supabase" ruling in
TASKS.md. See spec.md's Technical Decisions and Database Schema sections for
the target schema.

## Why

- Queue/allocation state (bags remaining, batch progression) must be shared
  live across buyer devices and the owner's device — a local-only DB can't do
  that.
- Notifications are core to the product (batch-ready alerts) and need a real
  push pipeline (FCM), which in turn needs a backend to trigger from.
- The app must keep working offline (buyers in Gaza markets with unreliable
  connectivity) — so the migration adds a backend, it doesn't remove the
  local DB.

## Phased rollout (app stays working at every step)

1. **Docs & config** — this doc + spec.md/TASKS.md updates (done); add env
   injection for `SUPABASE_URL`/`SUPABASE_ANON_KEY`.
2. **Supabase project + schema** — create the project, apply schema + RLS.
   App still runs entirely on drift.
3. **Auth migration behind a flag** — `SupabaseAuthRepository` alongside the
   existing drift-backed one, selected via a `useSupabase` flag (default off)
   until validated.
4. **Queue repository + offline sync** — `SupabaseQueueRepository` +
   `SyncService`; drift stays the UI read model, Postgres becomes the
   business-rule arbiter (sold-out checks, one-bag-per-day) via RPC
   functions. Offline writes queue locally and replay on reconnect.
5. **Realtime + push notifications** — `device_tokens` table, FCM wiring, a
   `notify-batch` Edge Function triggered off purchase/store changes.
   Realtime covers in-app live updates; FCM covers backgrounded/killed
   delivery.
6. **Cleanup** — remove the dead `dio`/`retrofit` scaffold
   (`lib/core/network/api_client.dart`, `api_service.dart`) and the
   `useSupabase` flag once Supabase is the stable default.

## Key architectural decisions

- **UUID primary keys** everywhere (not the current `INTEGER AUTOINCREMENT`),
  shared between drift and Postgres — the client generates the ID once, no
  server-id mapping table needed.
- **Drift is the single source of truth for UI reads**, kept current by a
  sync service (pull on reconnect + Realtime push-down). Supabase is the
  source of truth for enforcing business rules.
- **Business-rule writes move server-side**: `reserveBag`, `notifyNextBatch`,
  `saveStoreAllocation` become Postgres `SECURITY DEFINER` RPC functions so
  races (sold-out, one-bag-per-day) are resolved atomically in the database,
  not on-device.
- **Auth**: national-ID + PIN UX is preserved via a custom Edge Function that
  verifies the PIN (bcrypt via pgcrypto) and issues a Supabase session — this
  sidesteps the still-unresolved real SMS/OTP gateway question (see spec.md
  Open Questions) while still getting `auth.uid()`-backed RLS.
- **Notifications**: Supabase has no native push service. A DB
  trigger/Edge Function calls the FCM Admin API using tokens stored in a new
  `device_tokens` table; Realtime subscriptions handle in-app live updates as
  a complement, not a replacement.

## Deploy step: notify-batch shared secret

`notify-batch` runs with `verify_jwt` off (its caller is a DB trigger via
pg_net, which has no session), so it authenticates the caller with a shared
secret instead. Migration `20260921122111` generates that secret into Vault;
the function needs the same value as `NOTIFY_BATCH_SECRET`. It fails closed,
so pushes stay dead until this is run once per environment:

```bash
supabase secrets set --project-ref mgmerkaokkffsypnkryj \
  NOTIFY_BATCH_SECRET="$(psql "$SUPABASE_DB_URL" -tAc \
    "select decrypted_secret from vault.decrypted_secrets where name='notify_batch_secret'")"
```

To rotate: update the Vault row and re-run the command. Nothing else reads
it, and it never enters the repo.

## Open risks

- Real SMS/OTP provider still unresolved (spec.md blocker) — the Edge
  Function auth approach works without it but forfeits Supabase's built-in
  phone-auth flows.
- National-ID PII in a hosted DB — confirm Supabase's hosting region/DPA is
  acceptable before go-live.
- Offline conflict UX: a losing client in a race for the last bag needs a
  clear "rejected, please retry" surface, not silent disappearance.
- Existing PIN hashes (sha256) need a one-time re-hash-on-next-login to
  bcrypt since they aren't reversible.
