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
- Phone number + national ID + 4-digit PIN
- Bilingual (AR/EN), language toggle chip on screen
- No email, no passwords — works offline after first registration

**Buying Flow**
- Flat list of ~10 stores by name (no GPS — users recognize their local bakery)
- Each store shows: available / sold out
- One bag per national ID per store per day
- Pre-order today for tomorrow's bread
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

| Decision | Choice | Why |
|---|---|---|
| Platform | Android (Kotlin + Jetpack Compose) | Gaza device landscape, Jade's expertise |
| Backend | Supabase (Cloud) | Already in use, realtime DB, fast to prototype |
| Auth | Phone + national ID + local PIN | No email, works offline |
| Notifications (SMS) | httpSMS — one centralized phone, Jawwal SIM | One API per recipient, custom message per store |
| Notifications (fallback) | Push notifications (FCM) | Free, works when user opens app |
| Store discovery | Flat list by name | ~10 stores, no maps needed |
| Language | Bilingual AR/EN | Toggle chip on screen |

---

## Database Schema (Supabase)

### stores
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | text | e.g. "Al-Rimal Bakery" |
| owner_phone | text | hardcoded, links to owner account |
| is_open | boolean | purchase window toggle |
| daily_bag_limit | int | set by owner each morning |
| bags_remaining | int | live counter |

### users
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| phone | text | unique |
| national_id | text | unique |
| pin_hash | text | bcrypt hashed |

### purchases
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| store_id | uuid | FK → stores |
| user_id | uuid | FK → users |
| purchase_date | date | which day the bread is for |
| batch_number | int | which notification wave |
| status | enum | `waiting` → `notified` → `collected` |
| created_at | timestamptz | preserves purchase order |

UNIQUE constraint: (user_id, store_id, purchase_date)

---

## Open Questions

| # | Question | Status |
|---|---|---|
| 1 | **Jawwal Pay integration** — Does their business API support the SMS verification code flow? What payment methods do they offer for online merchants? | ⚠️ BLOCKER — Must confirm with Jawwal Pay / supervisor |
| 2 | **Push vs SMS ratio** — Should push notifications be primary with SMS as fallback (user hasn't opened app within X minutes of batch call)? | Open — leave for later |
| 3 | **Collection workflow** — How does an owner mark a batch as done? Manual per-person? Clear all at once? We'll learn during on-site pilot. | Open — learn from pilot |
| 4 | **Who pays SMS costs** — Costs run through the centralized httpSMS phone's Jawwal SIM. Who funds this? | Open |
| 5 | **WFP approval** — Required before expanding beyond pilot store. | External dependency |

---

## Process

1. Confirm Jawwal Pay integration (supervisor meeting)
2. Get WFP blessing for pilot
3. Build prototype: Kotlin Compose + Supabase + httpSMS
4. Pilot with 1 store — be on-site, train owner, learn collection workflow
5. Iterate and expand to ~10 stores
