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

Seeded on first run (drift `ensureSeeded`), then refreshed once per calendar
day. Every queue read filters on today's date, so a build installed one day
would show empty owner screens the next — instead, opening the app on a new
day lays down that day's queue and leaves earlier days in place for the
history screen. An APK built today demoes correctly tomorrow morning.

⚠️ Same-day re-runs still need a wipe: once أحمد buys his bag, the
one-bag-per-ID-per-day rule blocks a second live buy until tomorrow. To
rehearse and then demo on the same day, clear storage in between
(Settings → Apps → رغيف → Clear storage), which re-seeds from scratch.

Current accounts (existing):

| Role | Name | National ID | Phone | PIN | Note |
|---|---|---|---|---|---|
| Buyer | أحمد ناصر | 900111222 | 0599111111 | 1234 | seeded `verified` → skips photo gate |
| Owner | صاحب المخبز | 900333444 | 0599222222 | 1234 | owns مخبز الرمال |

Part 0 (richer seed) — ✅ BUILT (`feat/demo-seed`,
`flutter/lib/data/demo_content_seeder.dart`): the demo store (مخبز الرمال)
opens with today's queue already telling the full story at first glance:

- 3 rows COLLECTED (paid and picked up — batch 1)
- 3 rows NOTIFIED (paid, batch called — paid but hasn't picked up — batch 2)
- 3 rows WAITING (paid, batch not called yet — batch 3)

Plus 7 stores total (4 extra bakeries: مخبز الأمل، الزيتون، النور، السلام)
and 9 dummy registered buyers. The demo store's batch size seeds to 3 so the
three states land on three visible batches.

⚠️ The live demo buyer (أحمد, 900111222) has NO seeded purchase — the
one-bag-per-ID-per-day rule would block the live buy. Dummy buyers carry
their own IDs.

ⓘ This story is re-seeded automatically on each new calendar day — see
Demo data above for the same-day caveat.

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

**2. Store list — "where can I buy bread today?"** ✅ READY
- Shows the stores; tappable when open + has stock; closed/sold-out show
  "نفدت الكمية". ✅ A closed bakery now reads "مغلق" on a neutral chip
  instead of borrowing the sold-out wording.
- ✅ Search by store name or area, area filter chips, and pin-to-top. Stores
  the buyer actually uses float up by themselves (order today → bought before)
  and carry a richer card: order state, "مدفوع", last visit.
- Tapping a card now opens a **store details** screen (availability, my order
  + receipt QR, pin, last visit, buy CTA) instead of jumping straight to
  purchase.
- 🚧 Store numbers (for search-by-number) are still not a thing — see Roadmap.

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

**5. Receipt QR.** ✅ READY / ✅ restore
- Confirmation shows the QR (v1 payload: store, national ID, purchase id;
  error-correction H), with Save-to-gallery and Share. The QR is the
  pickup ticket.
- ✅ RESTORE: the buyer home ("طلبي") reopens the receipt at any time via
  "اعرض وصل الاستلام" — the QR no longer dies with the confirmation screen.
- ✅ Buyer home with live status (waiting → batch called → collected) exists
  now; you no longer have to re-enter the confirmation screen to check.
  ⚠️ No "how long until next batch" readout — that needs a REAL owner-set
  batch schedule (decision C removed the invented ETA).

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
- ✅ Confirm dialog before "Notify Next Batch": the dialog says how many
  buyers from earlier batches were called but never picked up (soft
  enforcement — a hard block would deadlock the owner when someone simply
  never shows up).
- ✅ waiting rows are amber — that matches UI_SPEC, which maps `warning`
  (#B45309) to "waiting/pending batch status". (An earlier note here claimed
  the spec wanted gray; it does not.)
- ✅ "Remaining didn't pick" visual: every batch header now carries the
  called / picked / still-waiting tallies.

**10. History page.** ✅ BUILT
- The owner dashboard now has "سجل المبيعات": a day browser over the same
  queue query. Each day shows sold / collected / outstanding — the demo closer
  ("أمس: 120 مبيعاً، 3 لم يستلموا") — and tapping a day lists its buyers with
  their status. One grouped per-day query, no full-table scans.

**11. QR scan at pickup.** ✅ READY / 🚧 sound + audit log
- Scan the buyer's receipt → five honest outcomes (checked in / already
  collected / batch not called / wrong store / not found on this device).
  Wrong-store is now decided from the code itself, no sync needed. Torch
  button for low light. National ID shows on the result card.
- ✅ SOUND: a distinct success/fail tone + haptic on scan (two-note "ding" for
  a handover, low buzz otherwise) — `assets/sounds/`, wired in the scanner.
- ✅ Scan audit log: every attempt is written to a `scan_events` table
  (store, purchase when matched, outcome, scanned name/national ID, timestamp)
  — "scan writes every detail to DB", and it feeds the history page.

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
   ✅ DONE — "طلبي" is the buyer's landing screen now.
3. Scan sound (success/fail + haptic) and scan audit log table.
4. Owner history page: date browser over the queue (incl. collected/
   uncollected end-of-day). ✅ DONE — "سجل المبيعات" on the dashboard.

P1 (sharpens the demo):
5. Store list: favorites pin-to-top + name search (+ store number if we
   add one to stores). ✅ DONE — search by name/area, area chips, pin-to-top,
   buyer-context sorting, and a store details screen.
6. Dashboard: pending count, low-stock in-app warning, confirm dialog on
   Notify, batch-release-after-collected enforcement.
   ✅ DONE — live "بانتظار الاستلام" count + in-app low-stock warning;
   Notify confirms and warns about uncalled-for leftovers (soft, not a block).
7. Per-batch "called/picked/left" summary on the queue.
   ✅ DONE — tallies in every batch header.

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
dashboard save bug fixed; customers screen (all-time); owner sales history
(date browser); buyer home ("طلبي") with the receipt QR restorable and live
order status; per-batch called/picked/waiting tallies; Notify confirmation;
dashboard pending-pickup count + in-app low-stock warning.

## What is MOCK / MISSING / PRODUCTION (don't overclaim)

- Payment, OTP, verification photos: mock (low-stock warning is in-app only
  — no SMS/push).
- No SMS/push ever sent (decision D; package installed, unused).
- No cross-device sync — redemption matches same-device data only.
- No owner history page, no buyer order home / QR restore, no scan sound,
  no cancellation, no selling hours, no payment record for owner.
  (✅ history page, buyer order home / QR restore and scan sound now exist —
  cancellation, selling hours and the owner payment record are still open.)
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
