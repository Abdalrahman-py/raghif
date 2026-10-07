# Raghif — رغيف

Digital queue + pre-order system for WFP bread distribution in Gaza.

WFP supplies selected markets with ~300 bags of bread daily (2kg pita, 3 ILS). Today hundreds
of people crowd a market at once. Raghif turns that into a queue: users reserve a bag from home
the day before, and the market owner releases customers in batches, notified by SMS.

## Status: prototype on a live backend

Flutter app under `flutter/`, backed by a live Supabase project (Postgres +
Realtime + Edge Functions + FCM push). The app keeps no local database:
every screen reads the server.

| File | What it is |
|---|---|
| [spec.md](spec.md) | Product spec — features, business rules, Supabase schema, open questions |
| [UI_SPEC.md](UI_SPEC.md) | Visual design system — tokens, type scale, per-screen layout |
| [constitution.md](constitution.md) | Non-negotiable project rules — read before changing anything |
| [TASKS.md](TASKS.md) | Prioritised backlog and working agreement |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How it fits together; where logic lives and why |
| [docs/BACKEND-REVIEW-2026-10.md](docs/BACKEND-REVIEW-2026-10.md) | Latest backend/logic review: findings, status, decisions needed |
| `flutter/` | Flutter app |

## Stack

Flutter + Supabase. Postgres decides (reservations, batch release, pickup,
allocation) and is the only source of data; the one thing kept on the phone is
the buyer's latest receipt, so the pickup QR opens with no signal. Writes
require the backend and fail loudly when it is
unreachable — a reservation that did not reach Postgres did not happen.

```bash
cd flutter
cp .env.example .env   # then fill in your Supabase URL + anon key
flutter run
```

The demo world (bakeries, buyers, today's queue) is seeded **server-side**
by the `seed-demo` Edge Function action, not by the app.

## Stack

| Layer | Choice |
|---|---|
| App | Flutter (Android first), Arabic only |
| Backend | Supabase: Postgres (RLS + RPC), Realtime, Edge Functions |
| Auth | National ID or phone + 4-digit PIN, via the `auth-gateway` Edge Function (5 wrong PINs lock the account 15 min) |
| Push | FCM, sent by the `notify-batch` Edge Function |

## Business rules (summary — [spec.md](spec.md) is authoritative)

- One bag per national ID per day across all stores; no cancellations
- Owner sets the daily allocation and batch size; the server decides what day it is (`Asia/Gaza`)
- Arabic only (no bilingual work until the owner says otherwise)

## Tests

```bash
cd flutter && flutter analyze && flutter test   # app
bash flutter/supabase/tests/run.sh               # SQL: RLS, grants, RPC rules (needs Docker)
```

## Blockers

Jawwal Pay integration and WFP pilot approval — see Open Questions in [spec.md](spec.md).
