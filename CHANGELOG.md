# Changelog

All notable changes to this project are logged here — **one entry per completed
task, appended after the work is done and before the commit is made.** The
format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project follows [Semantic Versioning](https://semver.org/) once there
is a numbered release to version. Until then, everything lands under
`[Unreleased]`.

Workflow rules this changelog lives by:

- A task is logged here **before** its commit — if the code changed and there
  is no entry, the change is not ready to commit.
- All changes reach GitHub as **clean PRs** (branch → CI green → review →
  merge to `master`). Nothing is pushed to `master` directly.
- Entries describe user- or repo-visible impact, not implementation trivia.
- History predating this file (2026-09-05) is preserved in `git log` and
  `TASKS.md` — this log starts at the current collaboration.

## [Unreleased]

### Added

- CHANGELOG.md — task log for the current collaboration (this file).
- PR-only GitHub workflow convention: work happens on a branch, CI
  (`flutter analyze` + `flutter test` + release APK) must pass, and merges
  to `master` happen only via reviewed pull requests.
- Owner pickup flow (#28 + audit items): QR redemption scanner on the buyer
  queue screen — new `qr_scanner_screen.dart` (mobile_scanner dependency +
  CAMERA permission) and camera-free decode/match logic in
  `qr_redemption.dart` with unit tests.
- docs/AUDIT-2026-09-05.md — code review report against `master` with a
  per-screen findings matrix and a prioritized P0–P2 task inventory.
- docs/PROTOTYPE-WALKTHROUGH.md — presentation script for the prototype
  demo (buyer + owner story), with each beat tagged READY / PARTIAL /
  BUILD / PRODUCTION, a build-order roadmap, and presenter guardrails.

### Changed

- Receipt QR payload is now versioned (`v: 1`) and carries `national_id` +
  `store_id` (both optional, so codes minted before the change still decode).
  The scanner can now report a wrong-store code from the code's own store
  claim — no local purchase needed — and shows the buyer's national ID on
  the scan result card. A `qr_payload.dart` header comment (Farid's) records
  the production roadmap: opaque signed server-issued token, no PII in the
  code, server-side redemption.
- Receipt QRs (on-screen, saved, shared) now render at error-correction
  level H (~30% recovery) instead of the default L — codes survive glare,
  blur, and screen reflections from photographed/phone-screen receipts.
- QR redemption scanner gains a torch (flashlight) toggle overlaid on the
  camera preview for low-light pickup counters — hidden automatically on
  devices without a torch; torch switches off when the camera stops.
- Owner queue buyer rows now show national ID + phone so pickup identity can
  be verified, with a live search field matching ID/phone suffix or name;
  the Notify-Next-Batch action is hidden during a search so a lookup can
  never release a batch accidentally.
- `PurchaseModel` and all repository row mappings now carry the buyer's
  national ID (users table join).

### Fixed

- Store list golden (`store_list_screen.png`) regenerated — it was stale
  against the current store card layout, failing CI (0.02%, 58px diff) on
  every branch regardless of its own changes.
- CI: the store list pixel golden flipped between green and red on
  byte-identical trees (0.002–0.005% of pixels: different CI runners
  rasterise fonts slightly differently), so master and every open PR showed a
  red build that had nothing to do with the branch. The golden is kept — the
  comparison now tolerates ≤ 0.1% of pixels and still fails on any real
  layout change (verified: a full-screen overlay still fails at 100%).
- Owner allocation save no longer resets today's remaining bags to the full
  daily limit, wiping out bags already sold before the save.
- Buying a bag after a store sells out is now rejected instead of silently
  clamping remaining stock to zero and completing the purchase anyway.
- Logging back in after registration/onboarding no longer leaves the stale
  login screen on top of the app.
- Registering with a phone number or national ID already on file now shows
  an Arabic message instead of a raw database exception.
- Registration form: the Jawwal Pay number now correctly defaults to the
  phone number typed above it. The old listener compared the updated phone
  against the wallet field's previous value, so it copied only the first
  keystroke and never tracked later edits. It now mirrors the phone until
  the user types their own wallet number (their value then wins; clearing
  the field restores the phone default).
- Flutter web build no longer fails to compile: `QueueController`'s no-DI
  fallback unconditionally imported `drift/native.dart` (`dart:ffi`), which
  isn't available on web, even though that fallback never runs once
  `main()` sets up DI. The native import is now conditional so web builds
  compile and behavior is unchanged elsewhere.
- PurchaseScreen no longer centers its content in the middle of the screen
  (leaving large dead space above and below on short content) — the store
  detail block now sits directly under the app bar and the buy/back buttons
  are anchored to the bottom.
- PurchaseScreen no longer shows the price twice — removed the separate
  price row since the buy button already states the amount.
- `OwnerDashboardScreen`'s allocation/batch-size fields could silently sync
  from stale placeholder data (`QueueController`'s hardcoded `defaultStores`)
  instead of the real repository values, because the widget couldn't tell
  the two apart once loaded. Added an explicit `storesLoaded` signal to
  `QueueController` so the one-time sync waits for real data.

### Added

- Pickup scans now play a tone and a haptic: a two-note "ding" when a bag is
  handed over, a low buzz for every other outcome (already collected, batch not
  called, wrong store, not found on this device, unreadable code) — so the owner
  can hear the result mid-queue without reading the screen. Tones ship as
  `assets/sounds/scan_success.wav` / `scan_failure.wav` via `audioplayers`,
  pinned below 6.8.0 because that release needs Flutter >=3.44 while CI builds
  on the pinned 3.41.6.
- Scan audit trail: new `scan_events` table (schema v5) records every attempt —
  store, matched purchase when there is one, outcome, scanned name/national ID
  and timestamp. This is the owner's "scan writes every detail to DB", and the
  raw material for the day/history view.
- **Store details screen** — tapping a store now opens a hub before buying:
  identity (name, area, availability, pin toggle), today's stock + purchase
  window, "طلبي اليوم" (order state, paid badge, and "اعرض وصل الاستلام" to
  reopen the receipt QR), the last visit, and the buy CTA. Cards stay tappable
  when a store is sold out or closed, since the screen is where that's
  explained.
- Buyer store list: **search** (store name or area), **area filter chips**,
  and **pin-to-top** — a pinned store always sorts first. Stores the buyer
  actually uses (an order today, or any past purchase) float up on their own
  and get a richer card: order state (بانتظار دورك / جاهز للاستلام /
  تم الاستلام), a paid badge, and the last purchase date (اليوم / أمس /
  date). Ordering/filtering lives in `store_list_logic.dart` (pure, unit
  tested). Schema v4 adds a per-buyer `store_pins` table and a
  `stores.area` column, both with migrations.
- Richer demo content for the walkthrough (P0-1) — new
  `lib/data/demo_content_seeder.dart` runs once after the base seed on fresh
  installs: 7 stores total (4 extra bakeries), 9 dummy registered buyers,
  and today's demo-store queue spanning all pickup states (3 collected /
  3 notified / 3 waiting across three visible batches). Kept separate from
  `ensureSeeded()` so existing tests see the old minimal footprint; the live
  demo buyer أحمد gets no seeded purchase (one-bag rule). Unit tests cover
  the seed, its idempotency, and the no-op-on-used-install guard.

- Store owners can now set today's purchase window (start/end time), shown
  to buyers on the store list and purchase screen alongside the existing
  bags-remaining count.
- Notifying the next batch now fires a real OS notification, simulating the
  push notification a buyer would get in production — there's no backend
  in this prototype, so it fires directly on whatever device runs the
  owner's "Notify Next Batch" action. Uses `flutter_local_notifications`
  (previously an unused dependency); no-op on web.

### Changed

- TASKS.md backlog synced with reality: #7 (real drift queries) and #8
  (widget tests) marked done — both closed COMPLETED on 2026-09-05; #28
  (store-owner QR redemption scanner) added as the only open item. Two
  collaboration rulings recorded there: app is Arabic-only for now (no
  EN/bilingual work), and the bag limit is one per national ID per day
  across all stores.
- TASKS.md collaboration rules hardened (agreed 2026-09-06): all work lands
  on feature branches only; `master` is never pushed to or merged to locally
  — it changes only via reviewed PRs; when `master` gains new code it is
  merged/rebased into working branches, never extended directly.

