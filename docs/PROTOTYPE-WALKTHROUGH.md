# Raghif prototype — demo walkthrough

Purpose: a script for presenting the prototype as a PRODUCT STORY (buyer +
owner), step by step. Every beat is tagged so the presenter never overclaims:

- ✅ READY — works today, safe to show
- ⚠️ PARTIAL — works with caveats / mock
- 🚧 BUILD — needed for the full story, not built yet (roadmap)
- 🔮 PRODUCTION — real-world concern, note only (not prototype scope)

Farid's framing (2026-09-06): show the app as two real users would use it
every day — a buyer who registers and buys bread, a store owner who sells,
scans receipts at pickup, and watches his day. Data is dummy; story is real.

---

## Demo data

Seeded on first run (drift `ensureSeeded`). ⚠️ Seeds apply to a FRESH
install only — existing test/dev installs need Settings → Apps → Raghif →
Clear storage to see the new data. Dates are computed as "today" at seed
time, so a fresh install demoes correctly on any day.

Current accounts (existing):

| Role | Name | National ID | Phone | PIN | Note |
|---|---|---|---|---|---|
| Buyer | أحمد ناصر | 900111222 | 0599111111 | 1234 | seeded `verified` → skips photo gate |
| Owner | صاحب المخبز | 900333444 | 0599222222 | 1234 | owns مخبز الرمال |

🚧 Planned richer seed (pending): 6–8 stores instead of 3; each with
registered dummy buyers; today's purchases at the demo store spanning all
pickup states so the queue tells the full story at first glance:

- several rows WAITING (paid, batch not called yet — didn't pick because not ready)
- several rows NOTIFIED (paid, batch called — paid but hasn't picked up)
- several rows COLLECTED (paid and picked up)

⚠️ The live demo buyer (أحمد, 900111222) must NOT have a seeded purchase
for today — the one-bag-per-ID-per-day rule would block the live buy.
Dummy buyers carry their own IDs.

---

## Part 1 — Buyer story (registration → bread in hand)

**1. Register (or sign in).** ✅ READY
- New user: name, phone, national ID, PIN → duplicate phone/ID shows an
  Arabic error (no raw DB exception).
- Then the verification gate: ID photo + selfie → ~3 s auto-approve
  (mock). ⚠️ Photo is displayed then discarded — say this is a mock;
  demo users skip the gate (seeded verified). 🚧 Gate has no skip/logout
  escape yet.
- Returning user: national ID → on-screen demo OTP → in (SMS is mocked).

**2. Store list — "where can I buy bread today?"** ✅ READY / 🚧 richer
- Shows the stores; tappable when open + has stock; closed/sold-out show
  "نفدت الكمية". ⚠️ Closed-vs-sold-out text is conflated today.
- 🚧 Sort & pin favorites on top; search by store name (and by a store
  number if we introduce one — see Roadmap). No GPS by design (spec).

**3. Store is open → buy one bag (3 ILS).** ✅ READY
- One-bag rule is checked BEFORE payment: same-day second bag anywhere →
  Arabic "already booked from another bakery today" message.
- ⚠️ Buying "for tomorrow" (spec: pre-order today for tomorrow's bread or
  the owner's selling window) is NOT in the app yet — 🚧 target-day
  selection is a roadmap item.

**4. Payment.** ✅ READY (mock, say it)
- Jawwal Pay mock: number → on-screen OTP → success. The OTP appears on
  screen because there is no SMS gateway. 🔮 Real Jawwal Pay API =
  open blocker; 🔮 over/under-payment handling is a production concern —
  today a purchase only exists AFTER payment succeeds, so a buyer can never
  reserve without paying (nothing to over/under-pay in the mock).

**5. Receipt QR.** ✅ READY / 🚧 restore
- Confirmation shows the QR (v1 payload: store, national ID, purchase id;
  error-correction H), with Save-to-gallery and Share. The QR is the
  pickup ticket.
- 🚧 MISSING for the story: a way to RESTORE the receipt later. Today the
  QR lives on the confirmation screen and (if saved) the gallery — if the
  buyer leaves the screen without saving, it's gone. Buyer home with "my
  current order → show QR" is a roadmap build.
- Buyer home with live status (waiting → batch called → picked up) and a
  "how long until next batch" readout is 🚧 — currently you must re-enter
  the confirmation screen to see status; there's no buyer dashboard.
  ⚠️ A time-to-next-shipment value must come from a REAL owner-set batch
  schedule, not the invented ETA we removed (decision C) — see Roadmap.

**6. Pickup.** 🚧 (needs restore + sound)
- Buyer opens the receipt QR at the counter → owner scans (Part 2).
  🔮 In production, pickup identity = the QR + national ID/photo check
  server-side (roadmap comment lives in `qr_payload.dart`).

## Part 2 — Owner story (sell, call, hand over)

**7. Owner identity.** ⚠️ PARTIAL
- Owners are seeded users (role column), no owner registration UI —
  صاحب المخبز / 0599222222 / PIN 1234 owns مخبز الرمال. 🔮 Owner
  onboarding is an admin/backend concern.

**8. Daily dashboard.** ✅ READY / 🚧 warnings
- Sets bags to sell (allocation), batch size; opens/closes the selling
  window (toggle). Remaining counter "X remaining". ✅ Save no longer
  resets sold bags.
- 🚧 Owner-set selling HOURS (open 06:00–09:00) — only a manual
  open/closed toggle exists today. The dashboard needs an open-hours
  schedule for the "window" to feel real.
- 🚧 Low-stock warning: when remaining bags drop under a threshold, warn
  the owner IN-APP (banner/badge). Actual SMS/push is out of scope
  (decision D — notification delivery is a separate workstream; this app
  only produces state).
- 🚧 Live "pending purchases" count on the dashboard (how many paid and
  not yet picked) — the queue screen has this live; the dashboard doesn't
  surface a count yet.

**9. Today's buyer queue.** ✅ READY
- Chronological, batch-grouped list; each row shows name + national ID +
  phone. Search filters by ID/phone/name and hides Notify while searching
  (a lookup can never release a batch by accident).
- Statuses visible per row: waiting / notified / collected.
- ⚠️ No confirm dialog before "Notify Next Batch" (audit open item);
  ⚠️ waiting rows are amber, UI spec says gray; 🚧 release-next-batch-only-
  after-collected discipline not enforced.
- 🚧 "Remaining didn't pick" visual: a per-batch summary (called N, picked
  M, M still to collect) so the owner sees who hasn't shown up.

**10. History page.** 🚧 NOT BUILT — answer to the question
- There is NO per-day sales history page today. The owner sees today's
  queue, and a Customers screen (all customers ever + their totals), but
  cannot look back at yesterday's or last week's queues.
- 🚧 Recommend: a date browser over the same queue query (repo already
  queries by date) — past days list, then a day's buyers with statuses,
  ending in collected/uncollected counts. Cheap to build, strong demo
  closer ("yesterday: 120 sold, 3 never picked up").

**11. QR scan at pickup.** ✅ READY / 🚧 sound + audit log
- Scan the buyer's receipt → five honest outcomes (checked in / already
  collected / batch not called / wrong store / not found on this device).
  Wrong-store is now decided from the code itself, no sync needed. Torch
  button for low light. National ID shows on the result card.
- 🚧 SOUND: a distinct success/fail tone on scan is not built (no audio
  asset/plugin wired). Build: short success "ding" + error buzz + haptic.
- 🚧 Scan audit log: today the scan only toggles the row's status; it does
  not write a scan record. If we want "scan writes every detail to DB",
  add a `scans` table (purchase, outcome, store, scanned_at) — also feeds
  the history page.

**12. Cancel a batch / tell buyers not to come.** ⚠️ CONFLICT — decide first
- Current spec says NO cancellations ("bag is paid for and owed") and the
  UI has no cancel action. Farid's story needs the owner able to cancel a
  batch (bakery failure) and buyers told. This is a product DECISION:
  add a `cancelled` purchase state + owner action + buyer-visible status.
  Notification DELIVERY stays out of scope (decision D) — the app shows
  the cancelled state; SMS/push tells them.

**13. Owner sees payment.** 🔮 PRODUCTION / 🚧 prototype option
- Today no payment data exists for the owner: payment is a mock that gates
  the purchase. A purchase row implies paid. A "paid ✓" badge per buyer is
  possible locally once we record the mock payment result; real payment
  reconciliation (amounts, over/under, refunds) is production-only.

---

## Roadmap — build order for the full story (suggested)

P0 demo-critical (before presenting the enriched story):
1. Richer seed: more stores + dummy registered buyers + today's mixed-
   status purchases at the demo store (this walkthrough's Part 0).
2. Buyer "my current order" home: restore the receipt QR + live status.
3. Scan sound (success/fail + haptic) and scan audit log table.
4. Owner history page: date browser over the queue (incl. collected/
   uncollected end-of-day).

P1 (sharpens the demo):
5. Store list: favorites pin-to-top + name search (+ store number if we
   add one to stores).
6. Dashboard: pending count, low-stock in-app warning, confirm dialog on
   Notify, batch-release-after-collected enforcement.
7. Per-batch "called/picked/left" summary on the queue.

P2 (product decisions first, then build):
8. Cancellation state + owner cancel action (decision needed — spec says
   no cancellations).
9. Owner selling hours (open/close schedule) + honest time-to-next-batch
   readout for buyers (needs owner-set batch times — do NOT resurrect the
   invented ETA, decision C).

## What is DONE (safe to claim)

Registration/login/logout real; verification gate mock; one-bag-per-ID
GLOBAL + checked before payment; purchases persist in drift; owner queue
with batch math + guarded search + national ID/phone rows; confirmation
plain-language (no fake ETA); QR receipt v1 (save/share, EC H) with
five-outcome redemption incl. wrong-store-from-code and torch; owner
dashboard save bug fixed; customers screen (all-time).

## What is MOCK / MISSING / PRODUCTION (don't overclaim)

- Payment, OTP, verification photos, low-stock warnings: mock or missing.
- No SMS/push ever sent (decision D; package installed, unused).
- No cross-device sync — redemption matches same-device data only.
- No owner history page, no buyer order home / QR restore, no scan sound,
  no cancellation, no selling hours, no payment record for owner.
- Production-only: real Jawwal API, signed server-issued QR tokens
  (no PII in code), server-side redemption, over/under-payment handling,
  identity check at pickup, FCM/SMS delivery.
- Audit open items: Notify confirm dialog, waiting-row color (gray per
  UI_SPEC), next-batch-after-collected, verification-gate escape.

## Presentation guardrails

- Two-phone redemption is a FUTURE story (sync). Demo pickup on one
  device or with a pre-printed receipt; never promise cross-device pickup.
- "Does it send SMS?" → "Not yet — the app produces the state change; the
  SMS/push layer is the next phase (separate workstream)."
- "How long until my batch?" → don't promise a time; show the batch +
  plain status. A real readout needs the owner's schedule (roadmap P2).
- "Is the QR secure?" → "Readable and unsigned on purpose in the
  prototype; production uses a signed server-issued token — the plan is
  written in qr_payload.dart."
