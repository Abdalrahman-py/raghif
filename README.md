# Raghif — رغيف

Digital queue + pre-order system for WFP bread distribution in Gaza.

WFP supplies selected markets with ~300 bags of bread daily (2kg pita, 3 ILS). Today hundreds
of people crowd a market at once. Raghif turns that into a queue: users reserve a bag from home
the day before, and the market owner releases customers in batches, notified by SMS.

## Status: prototype — throwaway

**This Android/Kotlin code will not ship.** It is a working prototype used to validate flows and
the design system. Production will be **ported to Flutter**. Treat everything under `app/` as
disposable; the durable artifacts are the two specs.

| File | What it is |
|---|---|
| [spec.md](spec.md) | Product spec — features, business rules, Supabase schema, open questions |
| [UI_SPEC.md](UI_SPEC.md) | Visual design system — tokens, type scale, per-screen layout |
| `app/` | Kotlin + Compose prototype (Room-backed, local only) |

## Prototype stack

Kotlin, Jetpack Compose (Material 3), Room, Navigation Compose. Min SDK 26.
Storage is local Room — Supabase and httpSMS from the spec are **not wired up yet**.

```bash
./gradlew assembleDebug        # requires local.properties with sdk.dir
```

## Production stack (planned)

| Layer | Choice |
|---|---|
| App | Flutter |
| Backend | Supabase (Postgres + realtime) |
| Auth | Phone + national ID + local 4-digit PIN |
| SMS | httpSMS via one centralized Jawwal SIM |
| Push fallback | FCM |

## What carries over to the Flutter port

- Schema in [spec.md](spec.md) (`stores`, `users`, `purchases`), including the
  `(user_id, store_id, purchase_date)` unique constraint
- Design tokens and per-screen layouts in [UI_SPEC.md](UI_SPEC.md)
- Business rules: one bag per national ID per store per day, no cancellations,
  owner-set batch size, bilingual AR/EN

## Blockers

Jawwal Pay integration and WFP pilot approval — see Open Questions in [spec.md](spec.md).
