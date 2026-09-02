# Raghif — رغيف

Digital queue + pre-order system for WFP bread distribution in Gaza.

WFP supplies selected markets with ~300 bags of bread daily (2kg pita, 3 ILS). Today hundreds
of people crowd a market at once. Raghif turns that into a queue: users reserve a bag from home
the day before, and the market owner releases customers in batches, notified by SMS.

## Status: prototype, in progress

Flutter app under `flutter/`, local-only (drift/sqlite3), no backend wired up yet.

| File | What it is |
|---|---|
| [spec.md](spec.md) | Product spec — features, business rules, Supabase schema, open questions |
| [UI_SPEC.md](UI_SPEC.md) | Visual design system — tokens, type scale, per-screen layout |
| [TASKS.md](TASKS.md) | Flutter build backlog |
| `flutter/` | Flutter app |

## Prototype stack

Flutter, drift (on-device sqlite). Storage is local — Supabase and httpSMS from the spec are
**not wired up yet**.

```bash
cd flutter && flutter run
```

## Production stack (planned)

| Layer | Choice |
|---|---|
| App | Flutter |
| Backend | Supabase (Postgres + realtime) |
| Auth | Phone + national ID + local 4-digit PIN |
| SMS | httpSMS via one centralized Jawwal SIM |
| Push fallback | FCM |

## Business rules

- One bag per national ID per store per day, no cancellations
- Owner-set daily batch size
- Bilingual AR/EN

## Blockers

Jawwal Pay integration and WFP pilot approval — see Open Questions in [spec.md](spec.md).
