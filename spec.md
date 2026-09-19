# Bread Distribution App — Product Spec

## Problem

WFP provides bags of bread (2kg pita, 3 ILS) through selected markets in Gaza. Each market receives ~300 bags daily. Currently, hundreds of people crowd the market at once — chaos, no order, unsafe.

## Solution

A mobile app that turns the market into a **digital queue + pre-order system**.
- Users reserve a bag from home the day before
- Market owners release customers in controlled batches (e.g., 20 at a time)
- Each batch gets notified by SMS when their bread is ready
- No crowd, no rush, everyone knows when to come

---

## Decided Features

### User Side

**Registration & Auth**
- Registration: phone number + national ID + 4-digit PIN
- Login identifier is national ID (unique, verifies the user) — not phone number
  - Default: OTP login — user enters national ID, app looks up the phone on file for
    that ID, simulates sending an OTP to it (shown on-screen — no real SMS gateway in
    the prototype), user enters the code to confirm
  - Alternate: PIN login — national ID + the 4-digit PIN set at registration, reached
    via a "log in with PIN instead" link on the OTP screen (only works if that ID has
    a PIN on file)

**Buying Flow**
- Flat list of ~10 stores by name (no GPS — users recognize their local bakery)
- Each store shows: available / sold out
- One bag per national ID per day, across all stores (not per-store)
- Pre-order today for tomorrow's bread or whenever the owner sets the timeframe for purchasing
- Fixed price: 3 ILS

**Waiting & Pickup**
- After purchase: confirmation with batch status
- User can check app anytime to see if their batch has been called
- SMS notification when batch is released: "Your bread is ready at [Store Name]"
- Push notification serves as fallback for SMS

### Market Owner Side

**Daily Dashboard**
- Set today's allocation (bags received from WFP)
- "Remaining: X / Y" live counter
- Purchase window: ON/OFF toggle
- Batch size: owner-set (e.g., 20 per batch)

**Buyer Queue**
- Chronological list of today's buyers
- Grouped into batches (batch 1, batch 2, batch 3...)
- Each buyer row shows: phone number, national ID, purchase time
- Notified batches = green, waiting batches = gray

**Batch Release**
- "Notify Next Batch" button — appears only when un-notified buyers exist
- Owner taps → confirms → SMS go out → batch moves to notified
- Owner releases next batch once current batch is collected

**Owner Identification**
- Hardcoded by phone number
- Same app, role-based switch — no separate app needed

### Business Rules
- No cancellations — bag is paid for and owed
- No reseller blocking (for now)
- No collection workflow defined yet — will learn during pilot
- Sold out = user sees "Sold out" only
- Start with 1 store, be on-site to train and monitor

---

## Technical Decisions

> **Status update (2026-09-19): moving to a live Supabase backend.** The
> earlier "prototype scope: local-only, no Supabase" ruling (2026-09-06,
> recorded in TASKS.md) is superseded by owner decision — the app is
> migrating to Supabase (Postgres + Realtime + Auth + Edge Functions) as the
> real backend, with the on-device `drift` database kept **permanently** as
> an offline cache/read layer (not a temporary shim). See
> `docs/supabase-migration-plan.md` (or the plan history) for the phased
> rollout. The SMS gateway is still unresolved (see Open Questions) — auth
> uses a custom Edge Function issuing sessions rather than Supabase's
> built-in phone-auth, so this doesn't block the migration.
>
> **Tooling note:** the `app/` Kotlin prototype uses SQLDelight (Kotlin/KMP-only — no
> Dart/Flutter codegen target). For the Flutter port, [`drift`](https://pub.dev/packages/drift)
> is the Dart-ecosystem equivalent — same SQL-file-first, generated-typesafe-query-code
> approach, sqlite3-backed. Confirmed by five independent implementations (PRs #15, #17,
> #19, #20, #21) converging on the same choice; see issue #4 for the full history.
> `drift` remains the local offline-cache technology under the new architecture.

| Decision | Choice | Why |
|---|---|---|
| Platform | Flutter (Android-first) | Port of the Kotlin prototype — the port IS the prototype now |
| Backend | **Supabase (Postgres + Realtime + Edge Functions)**, `drift` as permanent offline cache | Live multi-device state (queue/allocation must be shared across buyer + owner devices); drift keeps the app usable offline |
| Auth | National ID + PIN login, via a custom Edge Function issuing Supabase sessions | Preserves the no-SMS-needed UX while still getting real `auth.uid()`-backed RLS; real SMS/OTP gateway still unresolved (see Open Questions) |
| Notifications | Push notifications (FCM), triggered from Supabase via Edge Functions; Realtime for in-app live updates | Supabase has no native push service — FCM handles backgrounded/killed delivery, Realtime complements it while the app is open |
| Store discovery | Flat list by name | ~10 stores, no maps needed |
| Language | Bilingual AR | arabic only app |

---

## Database Schema

**Supabase Postgres is now the source of truth.** The on-device `drift` database
mirrors this schema as an offline cache (kept permanently, not a temporary shim) —
reads/writes go through Supabase when online, queue locally and replay when
offline. UUID PKs are shared between drift and Postgres (client-generated at
create time), so no separate server-id mapping is needed. Every synced table
carries `created_at`/`updated_at timestamptz` for sync cursors.

### stores
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | text | e.g. "Al-Rimal Bakery" |
| owner_id | uuid | FK → auth.users (replaces the old owner_phone match) |
| is_open | boolean | purchase window toggle |
| daily_bag_limit | int | set by owner each morning |
| bags_remaining | int | live counter, check constraint >= 0 |
| open_time / close_time | time | purchase window |
| batch_size | int | default 20 |
| area | text | |
| updated_at | timestamptz | sync cursor |

RLS: public read (buyers browse without auth); insert/update restricted to `auth.uid() = owner_id`.

### profiles
(was `users` locally — renamed to avoid colliding with Supabase's own `auth.users`)

| Column | Type | Notes |
|---|---|---|
| id | uuid | PK, = auth.users.id |
| phone | text | unique |
| national_id | text | unique |
| pin_hash | text | bcrypt via pgcrypto (migrated from the prototype's plain hash) |
| role | text | `buyer` \| `owner` |
| jawwal_pay_number | text | |
| verification_status | text | `pending` \| `verified` |
| updated_at | timestamptz | sync cursor |

RLS: self read/update; store owners can read profiles of buyers who purchased at their store.

### purchases
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| store_id | uuid | FK → stores |
| user_id | uuid | FK → profiles |
| purchase_date | date | which day the bread is for |
| batch_number | int | which notification wave |
| status | text (check) | `waiting` → `notified` → `collected` |
| created_at | timestamptz | preserves purchase order |
| updated_at | timestamptz | sync cursor |

UNIQUE constraint: (user_id, purchase_date). RLS: buyer owns their rows; store
owner reads/updates rows for their store. Writes go through a `reserve_bag`
Postgres RPC (SECURITY DEFINER) so the sold-out check and the one-bag-per-day
uniqueness are enforced atomically server-side, not racily on-device.

### device_tokens (new)
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → profiles |
| fcm_token | text | |
| platform | text | |
| updated_at | timestamptz | |

RLS: owner-only; the `notify-batch` Edge Function uses the service role to
read across users for push fan-out. See Notifications section below.

`store_pins` and `scan_events` keep their existing shape, UUID'd and owner-scoped via RLS.

---

## Open Questions

| # | Question | Status |
|---|---|---|
| 1 | **Jawwal Pay integration** — Does their business API support the SMS verification code flow? What payment methods do they offer for online merchants? A mock version of the expected flow (number entry → OTP → confirm) is specced for the prototype; real API integration is still unconfirmed. | ⚠️ BLOCKER (prototype uses a mock) — Must confirm with Jawwal Pay / supervisor |
| 5 | **WFP approval** — Required before expanding beyond pilot store. | External dependency |

---

## Process

1. Confirm Jawwal Pay integration (supervisor meeting)
2. Get WFP blessing for pilot
3. Build prototype: Flutter + drift (local DB, nothing hosted)
4. Pilot with 1 store — be on-site, train owner, learn collection workflow
5. Iterate and expand to ~10 stores
