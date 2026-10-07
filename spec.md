# Raghif — Product Specification

| | |
|---|---|
| Status | Prototype on a live backend, preparing a one-store pilot |
| Last reviewed | 2026-10-07 |
| Owner | Project owner (rulings in [constitution.md](constitution.md) §Authority) |
| Read with | [constitution.md](constitution.md) (rules), [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) (how), [UI_SPEC.md](UI_SPEC.md) (look), [TASKS.md](TASKS.md) (what next), [docs/BACKEND-REVIEW-2026-10.md](docs/BACKEND-REVIEW-2026-10.md) (known gaps) |

Requirement IDs (`AUTH-1`, `BR-3`, …) are stable: reference them in issues,
PRs and tests. A requirement is "built" only when a test cites it or the
review doc says why not.

---

## 1. Purpose

WFP supplies selected markets in Gaza with about 300 bags of bread a day (2 kg
pita, 3 ILS per bag). Today hundreds of people arrive at once: no order, no
fairness, no safety. Raghif turns the market into a **digital queue with
pre-orders**: a buyer reserves a bag from home, the market owner releases
buyers in batches, and each batch is told when to come.

### Goals
- G1. Nobody crowds the market: arrivals are spread by batch.
- G2. Fairness: one bag per person per day, first-come order, visible to the owner.
- G3. Works for low-literacy users on cheap Android phones, outdoors, on bad networks.
- G4. Cannot lose or double-sell a bag (the numbers are the product).

### Non-goals (do not build without a ruling)
Maps/GPS, multiple languages, a second payment provider, reseller detection,
cancellations or refunds, a web app, more than one pilot store's special cases.

### Pilot success criteria (proposed — owner to confirm)
One store, on-site, one full week: every reservation honoured or explained;
zero double-booked bags; owner releases batches without help by day 3; the
collection workflow (§5.4) is written down from what actually happened.

---

## 2. Users and roles

| Role | Who | Can |
|---|---|---|
| **Buyer** | Resident with a national ID | Browse stores, reserve one bag per day, see batch status, show a pickup receipt |
| **Store owner** | One person per store, assigned by the operator | Everything a buyer can, plus run their store's day (§4.3) |
| **Operator** | Project team | Creates stores and owner accounts out of band; there is no in-app admin |

"Owner" is a property of the store (`stores.owner_id`), granted by the
operator. A self-registered account is always a buyer.

## 3. Glossary

**Bag** — one unit of bread; the thing being rationed. **Allocation** — bags the
store received for a day (`daily_bag_limit`). **Reservation / purchase** — a
buyer's claim on one bag for one day. **Batch** — a group of consecutive
reservations (size set by the owner) released together. **Release / notify** —
the owner calls a batch. **Collect** — the owner confirms the buyer took the
bag. **Gaza day** — the calendar date in `Asia/Gaza`, by the server's clock.

---

## 4. Functional requirements

### 4.1 Accounts and sign-in
- AUTH-1. Register with phone, national ID, name, 4-digit PIN, and a Jawwal Pay number. Phone and national ID are unique. Self-registration creates a buyer.
- AUTH-2. Sign in with national ID **or** phone, plus PIN. Five wrong PINs lock that account for 15 minutes; the response never says which part was wrong.
- AUTH-3. OTP sign-in (national ID → code) is a **demo-only mock**, shown on screen, and disabled unless the backend sets `ALLOW_MOCK_OTP=true` (constitution VI). It is not a production login.
- AUTH-4. The session survives app restarts; sign-out clears it and the saved receipt.
- AUTH-5. Registration includes ID-photo and selfie capture (camera only, never gallery) and a simulated "waiting for verification" step that auto-approves. Real verification is out of scope for the prototype; the screen says it is simulated.
- AUTH-6. PIN, national ID and phone are never logged, put in a URL, or shown in an error (constitution IV).

### 4.2 Buying
- BUY-1. A flat list of stores by name, each showing **available** or **sold out**. No GPS.
- BUY-2. A buyer may pin stores; pins are stored server-side so a new phone keeps the order.
- BUY-3. A buyer reserves **one bag** for **today or tomorrow** (bounded by the server, BR-2). Price is fixed at 3 ILS; the prototype simulates payment with a Jawwal Pay mock (§10) and the counter-side collection workflow is undefined until the pilot (§5.4).
- BUY-4. Repeating a reservation request for the same store and day returns the existing reservation, not an error (retries are normal on bad networks).
- BUY-5. After reserving, the buyer sees a confirmation: store, day, batch number, status; and a pickup receipt that opens offline (§4.4).
- BUY-6. The buyer sees live status: `waiting` → `notified` (batch called) → `collected`.
- BUY-7. Sold out or closed shows "Sold out" and nothing else.

### 4.3 Store owner
- OWN-1. **Allocation:** set today's bag count, batch size and purchase window (open/close time); open and close the window with a toggle. Changing the allocation recomputes `remaining = limit − sold` for that day atomically.
- OWN-2. **Live counter:** "Remaining X / Y".
- OWN-3. **Queue:** today's reservations in purchase order, grouped by batch; each row shows name, phone, national ID and time. Called batches are visually distinct from waiting ones by colour **and** icon/text.
- OWN-4. **Notify next batch:** shown only when un-called buyers exist; confirm first; calls the lowest waiting batch and triggers one push per buyer in it.
- OWN-5. **Collect:** scan the buyer's receipt (or pick the row) → mark collected. A batch that has not been called yet cannot be collected; a second scan reports "already collected".
- OWN-6. Every scan outcome, including failures, is recorded for audit.
- OWN-7. **History:** per day — sold, collected, not collected. **Customers:** who bought, how often, last day.
- OWN-8. An owner sees only their own store's buyers; a buyer's data is never visible to other stores (constitution IV).

### 4.4 Pickup receipt
- RCP-1. The receipt shows a QR the owner scans; it must open without signal, so the latest receipt is the single thing cached on the phone, written only from a server answer and cleared on sign-out or when the server says the order is gone.
- RCP-2. *(Target, not built — review R-26.)* The QR carries an opaque, expiring, single-use server token only; no name or national ID. Redemption is one atomic server call that returns identity at that moment. Until then the prototype QR is a client-built JSON (version 2) that includes personal data and is validated against the owner's local queue. It must not be used with real identities.

### 4.5 Notifications
- NTF-1. Reservation confirmed → push to that buyer's devices, sent by the server.
- NTF-2. Batch called → push to every device of the buyers in **that** batch only.
- NTF-3. The app raises no notification of its own (constitution I).
- NTF-4. Push is the channel (decision D-5). The original SMS requirement is deferred until a gateway exists; push is also the fallback the original spec asked for. Delivery is best-effort today and not recorded (review R-09).

---

## 5. Business rules

- BR-1. **One bag per national ID per day, across all stores.** Enforced by a database unique constraint on (buyer, day), not by the app.
- BR-2. **The server decides the day** (`Asia/Gaza`). A reservation's date must be today or tomorrow; anything else is refused.
- BR-3. **No cancellations.** The bag is owed to the buyer; there are no refunds. What happens to uncollected bags is open (Q-4).
- BR-4. **Batches:** a reservation's batch is `⌊reservations so far that day ÷ batch size⌋ + 1`, assigned at reservation time under a store lock. Batch size changes affect only later reservations.
- BR-5. **Remaining bags** never go below zero; reserving decrements, allocation changes recompute from the day's sold count.
- BR-6. **Sold-out** is decided in Postgres at reservation time, never from a client-held count.
- BR-7. **Release order:** the owner calls the lowest-numbered waiting batch; batches cannot be skipped.
- BR-8. **No reseller blocking** in the pilot.
- BR-9. **Fixed price** 3 ILS.

### 5.1 Purchase lifecycle

```
reserve ──▶ waiting ──(owner notifies batch)──▶ notified ──(owner scans/collects)──▶ collected
```
Only these transitions exist; `collected` is terminal; `collect` on a `waiting`
purchase is refused; `collect` on `collected` is a harmless repeat.

### 5.2 Scan outcomes
`checkedIn`, `alreadyCollected`, `batchNotCalledYet`, `notFoundHere`,
`wrongStore`, `invalidCode`.

### 5.3 Purchase window
`is_open` plus optional `open_time`/`close_time` set what buyers may reserve.
Today the server enforces `is_open` and the remaining count; `open_time` /
`close_time` are informational (Q-6).

### 5.4 Collection workflow
Deliberately undefined until the on-site pilot (what the owner checks at the
counter, how disputes are settled). Record what is learned here.

---

## 6. Non-functional requirements

- NFR-1 **Accessibility is the product** — see constitution V (≥16sp body, ≥48dp targets, never colour alone, Arabic RTL only, no motion-forward UI).
- NFR-2 **Reliability** — a write that did not reach Postgres did not happen and says so; retries are safe (BUY-4); reads show nothing new rather than stale data.
- NFR-3 **Security & privacy** — RLS on every table, owner/buyer isolation, bcrypt PINs, no service-role key in the app, lockout on PIN guessing, no personal data in logs or QR codes (RCP-2).
- NFR-4 **Performance** — one store, up to ~300 reservations a day; a batch release wakes one batch of buyers at once. Reservation must stay correct under a burst of concurrent requests for the last bags (a SQL concurrency test is TASKS P1-6).
- NFR-5 **Supportability** — cheap Android phones; Flutter pinned in one place; every PR passes analyze, Flutter tests and SQL tests.
- NFR-6 **Operability** — a runbook (who, how to revoke sessions, restore) exists before the pilot (TASKS P1-5).

---

## 7. Data model

The migrations in `flutter/supabase/migrations/` are the schema's source of
truth; this section states the **meaning and invariants**, not every column.

| Table | Purpose | Key invariants |
|---|---|---|
| `profiles` | One per user; `id` = `auth.users.id` | phone and national ID unique; `pin_hash` bcrypt, never client-readable; `role` server-only; lockout counters server-only |
| `stores` | A bakery | `bags_remaining ≥ 0`; world-readable; **written only through RPCs** |
| `purchases` | A reservation | UNIQUE (`user_id`, `purchase_date`); status ∈ waiting/notified/collected; written only through RPCs |
| `store_pins` | Buyer's pinned stores | owner-only |
| `scan_events` | Pickup audit trail | store-owner read only; written by `record_scan` |
| `device_tokens` | FCM tokens | owner-only; service role reads for fan-out |

Known model gap: `stores.bags_remaining` is a single counter although buyers
can pre-order for tomorrow (review R-08). The target is a per-(store, day)
allocation row.

## 8. Roles, access and secrets
See [docs/ARCHITECTURE.md §4](docs/ARCHITECTURE.md). Anonymous users read
`stores` only; buyers read their own rows; owners read their store's purchases
and those buyers' profiles (never `pin_hash`); all writes are RPCs.

## 9. Interfaces

### 9.1 RPC catalogue (callable by `authenticated` unless noted)
| RPC | Caller | Effect | Refusals |
|---|---|---|---|
| `reserve_bag(store, date)` | buyer | Reserve one bag; idempotent per store/day | not authenticated; invalid purchase date; store closed or sold out; already reserved a bag today |
| `notify_next_batch(store, date)` | owner | Flip the lowest waiting batch to `notified`; triggers push | not the store owner; no waiting batch |
| `collect_purchase(purchase)` | owner | `notified` → `collected` | not the store owner; batch not notified yet |
| `save_store_allocation(store, limit, batch, date, open?, close?)` | owner | Set limit/batch/window; recompute remaining | not the store owner |
| `set_store_open(store, open)` | owner | Toggle the purchase window | not the store owner |
| `record_scan(store, outcome, …)` | owner | Append an audit row | not the store owner; unknown outcome |
| `set_store_pinned(store, pinned)` | buyer | Pin/unpin | not authenticated |
| `store_customers(store)`, `store_daily_summaries(store, limit)` | owner | Aggregates | not the store owner |
| `check_availability`, `create_profile`, `verify_pin_and_get_profile`, `find_profile_by_national_id`, `seed_demo_*` | **service role only** | Auth gateway and seeding | — |

### 9.2 Edge Functions
- `auth-gateway` — register, PIN login, (demo) OTP, availability check, gated demo seed.
- `notify-batch` — called only by database triggers with a shared secret; sends FCM pushes.

### 9.3 Realtime
Changes to `purchases` and `stores` trigger client re-queries. Realtime is a
refresh signal; data always comes from a query under RLS.

---

## 10. External dependencies and simulations

| Dependency | State | In the app |
|---|---|---|
| Jawwal Pay | Unconfirmed API; **mocked** (number → OTP → success) | Flow says it is simulated; success writes no "paid" fact. `verification_status` is currently cosmetic (D-1) |
| SMS gateway | None | Not used; push replaces it (D-5) |
| FCM | Live; needs `FCM_SERVICE_ACCOUNT` | Real pushes |
| WFP | Pilot approval pending | External gate before any expansion |

## 11. Decision log

| Date | Decision | Why |
|---|---|---|
| 2026-09-06 | Arabic only; one bag per ID per day across stores | Scope; fairness |
| 2026-09-19 | Supabase backend with custom ID+PIN gateway issuing real sessions | Shared live state; no SMS gateway yet |
| 2026-10-03 | No local database; buyer's receipt the only cache; server-only notifications | One source of truth; no stale answers |
| 2026-10-07 | Server owns the calendar, reservations idempotent, stores RPC-only writes, PIN lockout, mock OTP off by default | Review R-01…R-06 |

## 12. Open questions

| # | Question | Owner | Status |
|---|---|---|---|
| Q-1 | Jawwal Pay: does the merchant API support the verification-code flow; what methods for online merchants? | Supervisor meeting | ⚠️ Blocker for real payments; prototype mocks it |
| Q-2 | WFP approval to run the pilot | Project owner | External dependency |
| Q-3 | Real SMS gateway for notifications and OTP? | Project owner | Deferred; push is used |
| Q-4 | What happens to bags not collected by closing time? | Project owner | Open (D-4) |
| Q-5 | Is `verification_status` enforced before a purchase? | Project owner | Open (D-1) |
| Q-6 | Should the server enforce `open_time`/`close_time`? | Project owner | Open |
| Q-7 | Per-day allocation and rollover rules (R-08, D-2) | Project owner | Open |
| Q-8 | 4-digit PIN acceptable for the pilot (D-3)? | Project owner | Open |

## 13. Pilot process

1. Confirm Jawwal Pay (Q-1) and WFP blessing (Q-2).
2. Close the P0 items in [TASKS.md](TASKS.md).
3. Seed **nothing** demo-related into the pilot project; create the store and owner as the operator.
4. One store, on site, train the owner, write §5.4 from what happens.
5. Iterate; expand to ~10 stores only after WFP approval and a staging environment exist.
