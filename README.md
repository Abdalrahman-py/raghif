# Raghif — رغيف

Digital queue + pre-order system for WFP bread distribution in Gaza.

WFP supplies selected markets with ~300 bags of bread daily (2kg pita, 3 ILS). Today hundreds
of people crowd a market at once. Raghif turns that into a queue: users reserve a bag from home
the day before, and the market owner releases customers in batches, notified by SMS.

## Status: prototype on a live backend

Flutter app under `flutter/`, backed by a live Supabase project (Postgres +
Realtime + Edge Functions + FCM push). The on-device `drift` database is a
cache of that server, not a second source of truth.

| File | What it is |
|---|---|
| [spec.md](spec.md) | Product spec — features, business rules, Supabase schema, open questions |
| [UI_SPEC.md](UI_SPEC.md) | Visual design system — tokens, type scale, per-screen layout |
| [TASKS.md](TASKS.md) | Flutter build backlog |
| `flutter/` | Flutter app |

## Stack

Flutter + Supabase. Postgres decides (reservations, batch release, pickup,
allocation); `drift` caches the answers so the app still renders on a bad
connection. Writes require the backend and fail loudly when it is
unreachable — a reservation that did not reach Postgres did not happen.

```bash
cd flutter
cp .env.example .env   # then fill in your Supabase URL + anon key
flutter run
```

The demo world (bakeries, buyers, today's queue) is seeded **server-side**
by the `seed-demo` Edge Function action, not by the app.

## Production stack (planned)

| Layer | Choice |
|---|---|
| App | Flutter |
| Backend | Supabase (Postgres + realtime) |
| Auth | Phone + national ID + local 4-digit PIN |
| Push | FCM |

## Business rules

- One bag per national ID per day across all stores, no cancellations
- Owner-set daily batch size
- Bilingual AR/EN

## Blockers

Jawwal Pay integration and WFP pilot approval — see Open Questions in [spec.md](spec.md).
