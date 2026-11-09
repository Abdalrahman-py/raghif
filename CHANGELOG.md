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
### Fixed — 2026-11-09 — server side of the PR 68 review: simulated payments, lock order, anon aggregate, search_path

Migration `20261109120000_payment_and_grant_review_fixes` (**not applied live**;
apply it, then record the version in `supabase_migrations.schema_migrations`):

- **A simulated wallet payment never counts as money received.** Decision: the
  smallest correct fix is at collection. When the owner collects a bag whose
  only payment is `provider = 'simulated'`, `collect_purchase` turns that row
  into the cash row (price at pickup). `store_daily_summaries` already counts
  `method = 'cash'` only, so "cash taken" now includes these bags and never a
  simulated one. A real `provider = 'jawwal_pay'` row is untouched. Rows
  collected before the migration are not rewritten (unknown whether cash was
  taken). `record_wallet_payment` still has no code check; with this change it
  can no longer make a bag look paid on the server.
- `record_wallet_payment` now locks the stores row first, then the purchase row
  (it locked the purchase first).
- **`popular_stores` is dropped.** It let `anon` aggregate `purchases`, against
  "anon may read `stores` and nothing else". Its only caller was the signed-out
  home, which now ranks the five bakeries that sold most today from `stores`
  (its old fallback) and no longer calls the RPC. Older builds get an error and
  use the same fallback. `QueueRepository.getPopularStoreIds` is removed.
- `reserve_bag` and `record_scan` now run with `search_path = ''` (bodies were
  already fully qualified; date check and lock order unchanged).
- New rollback-only suite `supabase/tests/review_fixes.sql`;
  `wallet_payment.sql` updated to the new collection rule.

### Fixed — 2026-11-09 — simulated wallet payment no longer tells the bakery "don't take cash"

- Every booking made in the app records a stand-in wallet payment
  (`provider = 'simulated'`, code 1234, no money moves). The app read any
  `jawwal_pay` row as prepaid, so the owner's scanner and queue said
  "مدفوع مسبقًا عبر المحفظة: لا تأخذ نقدًا" and the bag was handed over unpaid.
  Purchases now read `payments(method, provider)` and a simulated payment maps
  to `paymentMethod = 'simulated'`, which is not prepaid: the owner is told to
  take cash and the buyer's receipt says cash is due. Only a real
  `provider = 'jawwal_pay'` payment will count as prepaid.
- Sign-in error, owner queue search hint and sign-out warning no longer mention
  the national ID (removed on 2026-11-08); they say phone number.
- Found in review of the `obaida` branch before merging it to `master`.
  Server side unchanged: `store_daily_summaries` still counts simulated bags as
  no cash, and `record_wallet_payment` still accepts a call without any code.

### Changed — 2026-11-08 — no live connection: data is read on demand

- Realtime is gone. The app keeps no websocket and nothing downloads on its
  own. Screens read when opened, after the person's own actions, on
  pull-to-refresh (bakery list, receipt, owner dashboard/queue/customers), when
  a push arrives while the app is open, and when the app returns after a
  minute or more away. A failed read is not retried on a timer; the retry
  button or a pull renews it. Replaces the retry/back-off and per-table
  filtering added earlier today.
- Migration `20261108150000_drop_realtime` removes `purchases` and `stores`
  from the `supabase_realtime` publication, so the server stops fanning out
  changes.
- Checked in the web build: no websocket, one store read per screen, the
  connection probe every 30 s, buyer sign-in and home load normally.

### Changed — 2026-11-08 — less data on weak connections

- Reads ask for named columns instead of `*` (stores, purchases); the buyer's
  booking history in the bakery list is capped at the newest 100; the inbox
  fetch drops from 100 to 50 rows.
- The store list is fetched once and shared by every screen that asks for it
  within two seconds (it used to be downloaded 2-3 times per change).
- Live updates wait 2 s (was 0.35 s) after the last Realtime event before
  re-reading, and a failing read backs off 10 s, 20 s, 40 s ... up to 2 min
  instead of retrying every 10 s.
- Live streams re-read only for the table they show (a booking-only stream no longer reloads on store changes), the bakery list waits 4 s, and while the app is in the background nothing is downloaded: one read on return if anything changed.
- The connection bar probes every 30 s (was 6 s) with a HEAD request on a
  kept-open connection.

### Added — 2026-11-08 — offline reading for owners, and a connection bar

- A bar across the top of the app shows whether the server can be reached:
  amber "no connection, showing last saved data" while offline, green "back"
  for two seconds on return. It probes `/auth/v1/health` every 6 s (a phone on
  Wi-Fi with no internet counts as offline). `http` is now a direct dependency
  (it was already pulled in by supabase_flutter).
- Owners get the same read-only fallback buyers had: their bakery and today's
  queue are saved and shown when the server cannot be reached, so the
  dashboard and queue open offline. Writes still need the server.
- Fixed: the saved copy was erased on every app start (the session-restore
  state change ran `resetForSession`, which cleared the cache before an offline
  start could read it). It is now cleared only when a signed-in person leaves.

### Changed — 2026-11-08 — buyer home: "my bakeries" is the default filter

- The buyer's list of bakeries starts on a "مخابزي" chip (the last five bakeries
  they bought from, most recent first), placed before "الكل" and the
  governorate chips. A buyer with no history sees everything as before.

### Changed — 2026-11-08 — national ID removed; the phone number is the Jawwal Pay number

- The national ID is gone from the app and the database (`profiles.national_id`,
  `scan_events.scanned_national_id`, the QR payload, owner queue/history rows
  and search, admin buyer search). Not published yet, so the columns were
  dropped outright (migration `20261108120000_drop_national_id`).
- One number for everything: it is the sign-in name, the Jawwal Pay wallet and
  the uniqueness key (`profiles_phone_key`). `profiles.jawwal_pay_number` is
  dropped. Registration is three steps (name, phone, PIN) and the phone must be
  a 056/059 number.
- `login-pin` takes `{phone, pin}`; `login_attempt(phone, pin)`,
  `check_availability(phone)`, `create_profile` (no ID/wallet),
  `update_my_profile(name)` (the phone is support-only),
  `verify_my_wallet(code)` (verifies the account's own phone; the code is still
  the stand-in 1234 until SMS exists), `record_scan` and `admin_list_buyers`
  were recreated without the removed columns.
- New accounts get a random sign-in address (`u-<uuid>@raghif.internal`) and
  the gateway reads it back from the auth user, so it no longer depends on the
  phone. Existing demo users keep their old `nid-…` address until cleaned up.
- Fixed a gateway bug: redeeming a session on the shared service-role client made
  every later call in a warm instance run as `authenticated` ("permission
  denied for function login_attempt"). A throwaway client now redeems it, and
  `register` no longer treats a failed availability check as "phone free".
- Demo auth rows now carry `instance_id` and empty token strings so the auth
  server can load them; the admin panel (`raghif-admin`) drops the ID column,
  field and search.
- Removed the legacy `seed-demo` gateway action and `seed_demo_*` functions;
  `supabase/demo/seed_demo_data.sql` now signs in by phone
  (0569000001…100 buyers, 0568000001…05 owners, PIN 2580).

### Added — 2026-11-06 — owner: next-batch suggestion and last-7-days stats

- The owner's home shows a "time for batch N" card when someone is waiting and
  at most a quarter of the batch size (max 5) of the called buyers are still
  out. It only opens the queue; calling a batch still needs confirmation.
- A "last 7 days" card: bags sold, collected %, daily average, cash taken and
  best day, from the existing per-day summaries (no new backend).
- Admin panel (`raghif-admin`): bakeries without a governorate are flagged
  "بلا محافظة" and the edit form no longer silently defaults to غزة.

### Changed — 2026-11-06 — signed-out home shows the 5 busiest bakeries

- Migration `20261106120000_popular_stores` (applied live, version aligned): `popular_stores(p_limit)` returns ids and booking counts of the busiest active bakeries over the last 7 days; callable by visitors, no buyer data.
- The visitor's first screen lists only those 5 ("الأكثر طلبًا هذا الأسبوع"); the summary line still counts every bakery. If the ranking cannot be fetched it falls back to the 5 that sold most today.

### Changed — 2026-11-06 — speed and offline reading

- Bread image 1.4 MB PNG -> 35 KB WebP (`stitch_bread.webp`); unused Noto Sans Arabic font removed.
- Start-up: Supabase, the notification channel and Firebase initialise together instead of one after the other.
- Owner sales history loads the newest 30 days with "عرض المزيد" (was 366 days at once); the customer list shows 30 at a time.
- Realtime refreshes are coalesced (one re-read 350 ms after the last change instead of one per row).
- Release builds (`apk.yml`, `release.yml`) add `--obfuscate --split-debug-info`.
- Buyer home: search by bakery name or area.
- Offline reading (`core/cache/offline_cache.dart`): the last bakery list and the last receipts (with the QR) are saved on the phone and shown, marked as old, when the server cannot be reached. Cleared on sign-out. Writes still go to the server only.
- AGENTS.md: removed notes that were out of date (postponement does push; `original_purchase_date` is shown; notification copy migrated).

### Fixed — 2026-11-06 — wrong PIN retry, profile menu, daily quantity row

- Sign-in: after a wrong PIN the field was disabled while the request ran, lost focus, and kept the wrong digits. It now stays enabled (read-only while loading), is emptied and focused again on failure, and a second submit while loading is ignored.
- Profile: privacy policy, terms of use and the delete-account request moved from the page into a three-dots menu in the app bar (`AccountMenuButton`; the buyer shell shows it on the account tab).
- Bakery dashboard: the "الكمية اليومية" stepper sits in the same row as its label.

### Changed — 2026-11-06 — buyer/owner redesign, splash, WhatsApp support, demo data

- Buyer home rebuilt: last 3 bakeries, governorate filter, open bakeries first, horizontal cards (green open / red closed or sold out), one-tap "اشترِ ربطة" straight to payment; the review screen, the governorate/area pickers and the old store list are removed. Bookings go through `queue/purchase_flow.dart`.
- Bakery owner gets bottom tabs (الرئيسية · سجل الزبائن · سجل المبيعات). Shared `AppBottomBar` restyles both tab bars. Status chips that repeated the headline were removed from "حجزي", the receipt and the bakery page; "حجزي" no longer has a browse button.
- Palette: the bread-brown / beige accent is replaced by the brand blue (`app_colors.dart`).
- New animated splash (`features/splash`). Notification permission is no longer asked during start-up: push starts 1.5 s after the first frame (`startPushLater`), so a waiting dialog cannot hold the app. Firebase is skipped on web.
- WhatsApp support button (`core/support/support_contact.dart`, `url_launcher`): guest home next to "هل أنت صاحب مخبز؟", forgot-PIN dialog, account screen, delete-account dialog.
- Demo data for trying the app: `supabase/demo/seed_demo_data.sql` (15 bakeries, 5 owners, 100 buyers, a week of bookings; ids `de[012]00000-...`; PIN 2580) and `supabase/demo/cleanup_demo_data.sql` to remove exactly those rows. Seeded into the live project on 2026-11-06 at the owner's request.
- `docs/screens-and-redesign-prompts.md`: every screen's contents and an AI redesign prompt for each.
- `.claude/launch.json` works on Windows (no `bash`/`python3`).

### Changed — 2026-11-05 — notification copy, Firebase tooling, Gradle 8.14

- Migration `20261105150000_notification_copy` (applied live): clearer Arabic text for the confirmed / postponed / ready notifications, dates as DD/MM/YYYY.
- `flutter/firebase.json` points at `ragheef-b8c20`. Gradle wrapper 8.12 -> 8.14 (the installed Flutter 3.47 refuses anything older).
- Demo-data cleanup was run by the owner in the Supabase SQL editor.
- Bakery owners are created only by the administrator in the panel; there is no owner self-registration (decision, not a gap). Remote alerts are by WhatsApp to the support number; there is no automatic sender yet.

### Changed — 2026-11-05 — wallet verification live; postponed bookings show their original day

- Migration `20261105140000_wallet_verification` applied to the live project (version aligned); client `UPDATE` on `verification_status` / `jawwal_pay_number` is now closed.
- A postponed booking shows "تم تأجيله من يوم …" (`purchases.original_purchase_date` is finally read).
- Demo-data cleanup (disable the 12 demo accounts, archive the 7 demo bakeries) is NOT done: the live SQL was blocked by the session's permission guard and is left for the owner.

### Changed — 2026-11-05 — buyer verification by Jawwal Pay number (replaces ID/selfie)

- The ID photo, selfie and fake "reviewing" screens are gone (and the `image_picker` dependency). A new buyer confirms the Jawwal Pay number instead: the number is entered, a code is "sent" (simulated, always 1234, shown on screen) and typed back.
- Migration `20261105140000_wallet_verification` (written, not yet applied live): `verify_my_wallet(number, code)` checks the code on the server and sets `verified`; changing the wallet number via `update_my_profile` resets a buyer to `pending`; direct `UPDATE` on `verification_status` / `jawwal_pay_number` is revoked. Closes the old "client can flip its own verification" issue. SQL test `wallet_verification.sql` added.
- Real SMS arrives with the Jawwal Pay gateway: replace the `'1234'` comparison and add an attempt limit then.

### Changed — 2026-11-05 — app moved to the new Firebase project

- `android/app/google-services.json` and `lib/firebase_options.dart` now point at project `ragheef-b8c20` (Android app `com.raghif.raghif` registered there through the Firebase Management API with the service-account key). This matches the `FCM_SERVICE_ACCOUNT` secret already on the server, so push can be delivered once a new APK is installed. The old web options are removed (the app is Android-only).
- `db-backup.yml`: nightly schedule switched off (manual run only) until the project moves to Supabase Pro; no secrets are needed meanwhile.


### Added — 2026-11-04 — admin panel rollout (live)



- The six admin-panel migrations are applied to the live project; `admin-api`, `send-push` and `auth-gateway` (v16) are deployed. The first administrator is in `public.admins`; admin RPCs verified as that user inside a rolled-back transaction.
- Panel published from the public repo ObaidaAlaff/raghif-admin (GitHub Pages: https://obaidaalaff.github.io/raghif-admin/). `admin/` README section added to the project README.
- Still open: `FCM_SERVICE_ACCOUNT` push secret (Firebase project mismatch: app `raghif` vs key `ragheef-b8c20`), `announcementsReady` stays false until the app ships, `verification_status` self-service decision.



### Added — 2026-11-04 — admin panel, phase 1 (database; not applied)

- Plan: `docs/superpowers/plans/2026-11-04-admin-panel.md` — seven phases for a programmer-only admin panel (Vue via CDN on GitHub Pages) that manages bakeries, buyers, stats and announcements.
- Four new migrations, **written and reviewed-ready but not applied to the live project**: `admin_foundation` (admins + `is_admin()`, `stores.bag_price` default 3, `stores.status` active/paused/archived, `profiles.account_status`, archived stores hidden from buyers, `reserve_bag` refuses paused/archived stores and disabled accounts, `DELETE` revoked on stores/profiles, `account_login_block`), `admin_rpcs` (overview, daily series, scans, notification stats, bakery and buyer lists, status/verification/price edits), `notifications_announcements` (announcement kind, nullable `purchase_id`, `admin_send_notification`) and `change_my_pin` (owners only, 5 misses lock 15 min, weak PINs refused).
- New SQL suite `tests/admin_panel.sql`, added to `tests/run.sh`. Verified on a local real Postgres (PGlite — no docker here): every migration plus all six SQL suites pass. The four new migrations were also dry-run on the live schema inside one transaction that ends in a deliberate error, so nothing was applied.
- Phase 2 (not deployed): migration `admin_service_helpers` (`admin_revoke_sessions`, `admin_set_pin`), new edge function `admin-api` (create a bakery with a one-time random PIN, reset a PIN, set store/account status and sign the user out; admin JWT required, service key only after `is_admin()`), 18 Node tests for its logic, and `auth-gateway` now answers 403 `account_disabled` / `store_archived` instead of "invalid credentials" (a missing database function is treated as no block so an early deploy cannot lock everyone out).
- Phase 3 (not deployed): edge function `send-push` (pushes one inbox row to its owner's devices through FCM, drops dead device tokens, fails closed without the shared secret; 9 Node tests) and migration `inbox_push_trigger`, which pushes `postponed` and `announcement` rows — closing the "postponement sends no push" gap — while `confirmed`/`ready` stay with the existing triggers so nobody is buzzed twice. New SQL suite `tests/inbox_push.sql`.
- Phase 4 (not deployed): the admin panel itself in `admin/` — Vue 3 from a pinned, SRI-checked CDN with no build step, Arabic RTL in the app's palette. Sign in (admin only), overview with a 30-day chart, bakeries (create, edit, pause/archive with confirmation, one-time PIN), buyers (search, verify, disable), statistics and an announcement form that stays disabled until the app can show announcements. Exercised only against built-in sample data (`?mock=1`, localhost only); never run against the real backend.
- Phase 5 (not published): `admin-pages.yml` deploys `admin/` to GitHub Pages on changes to it (an explicit five-file list, and it fails if a secret key or any JWT ends up in the site); `ci.yml` gains an `edge-functions` job running the 27 Node tests; `admin/README.md` documents creating the administrator account and the Pages setup.
- Phase 6 (app, not shipped): owners can change their PIN from the account screen (current PIN + new PIN twice, errors from the server shown in Arabic); a disabled account or archived bakery is told so at sign-in instead of "wrong PIN"; stores carry the administrator's `status`, so a paused bakery shows "متوقف مؤقتًا" and cannot be booked; announcements (no booking behind them) display and can be marked read instead of crashing the inbox. Verification is still self-service pending a product decision (see the plan).
- Phase 7 preparation (nothing applied): `supabase/rollback/20261104_admin_panel_rollback.sql` undoes the six admin-panel migrations. Verified locally: after applying everything and writing data into the new columns, running it restores the schema exactly (columns, functions and their grants, policies, constraints, triggers, indexes, privileges) and keeps stores and profiles. A runbook for applying to the live project is in the plan.
- Known follow-up (resolved by phase 6 once the app ships): the app reads `notification_inbox.purchase_id` as non-null, so no announcement may be sent before the app change in phase 6.

### Fixed — 2026-11-04 — launch screen on every app open

- Removed the "ابدأ التجربة" launch screen. Its "started" flag was never persisted, so every user (owner or buyer, signed in or not) had to tap through it on every cold start. The app now goes straight to the session check, then onboarding (once per install), login or home.
- Owner dashboard: removed the large "المتبقي اليوم" hero card. The stat cards right below it already show remaining, pending pickup and daily allocation, so the same numbers appeared twice. The sold-out / low-stock notice stays, now directly under the stat cards.
- Owner dashboard: the save-today's-settings button now shows a spinner and ignores taps while the save is in flight, so it can't be submitted twice.
- Owner customers log (سجل الزبائن): removed the bakery-name card at the top (the owner already knows which bakery it is) and numbered each customer card 1, 2, 3… in the avatar circle.
- Owner dashboard: the open/close-bakery switch shows a spinner and ignores taps while its write is in flight.
- Owner sales history (سجل المبيعات): removed the bakery-name card; days are now a table (day | sales | collected | not collected) with the Arabic weekday name above each date, and the day screen title includes the weekday. Added filters by month and by a single day. The list now loads up to 366 days (was 30) so the filters reach back past last month.
- Owner dashboard: removed the sign-out button (it lives on the account screen) and put the profile button where the bakery logo was, next to the bakery name. Account screen: no more "copy ID number" button for owners.
- Booking-confirmed screen (تم حجز ربطتك): all details fit on one screen (scaled to fit, not scrolled) and the three actions — save, share, home — are pinned at the bottom in one row.
- My booking (حجزي): removed the "browse bakeries" button from an existing booking and the three-step progress list (booked / ready / collected), which repeated the status chip and banner above it. The empty state keeps its browse button.
- Account screen: removed the "copy ID number" button for everyone, not just owners.
- Bottom navigation bar restyled to match the app: white strip with a hairline, accent-colored selected tab with a soft pill.
- Replaced the beige ground (and its tinted borders/containers) with a light blue-grey across the app, the native splash screen and the loaf artwork.

### Fixed — 2026-10-29 — migration audit and team APK builds

- Classified the two live Gaza City areas the governorate backfill missed (Sheikh Radwan, Tal al-Hawa), so every current store is reachable from the governorate screen instead of only browse-all.
- Indexed `notification_inbox.purchase_id` for the purchase-delete cascade, and revoked the unused `TRUNCATE`/`REFERENCES`/`TRIGGER` grants from `anon`/`authenticated` plus anon's unused DML — row level security is no longer the only barrier on the older tables.
- Applied the four redesign migrations and the hardening migration to the live project through the Supabase MCP; the inbox and profile/postpone SQL suites now run against that schema and pass (rollback-only).
- Added `.github/workflows/apk.yml`: debug and release APKs built with the real Supabase project from repo variables, uploaded as one artifact, never replacing the rolling `latest` release. Both APK workflows raise the Gradle heap to 4 GB on runners only — the 1536 MB laptop setting OOMs Jetifier on the Flutter engine jar.
- Added `AGENTS.md`: the queue/RLS invariants, the open security decisions, and the unmerged `chore/backend-hardening-and-spec-rewrite` work any agent must reconcile before changing the backend.

### Added — 2026-10-27 — buyer Stitch flow

- Added governorate and area selection, an authenticated notification inbox, account/profile editing and tomorrow-postponement confirmation directly in the existing Flutter project. Reused the established cream/brown theme, RTL typography and existing layers; added buyer Home/My booking/Account navigation and owner account/inbox actions.
- Kept geography based on actual stores, provided explicit loading/error/retry states, isolated session data on logout/user changes, and protected profile saves from duplicate submissions and late replies. Postponed bookings retain their identity/payment, consume tomorrow's quota/capacity, remain visible ahead of collected-today receipts, and invalidate the old-date QR.
- Added four ordered Supabase migrations and scoped SQL tests. **Migrations are not deployed and SQL tests were not executed here**; live inbox, profile saving and postponement require the server deployment described in `docs/superpowers/plans/2026-10-27-server-deployment.md`. No production booking/profile/database writes were made for preview.
- Verified the full Flutter suite: 269 pass, 2 existing skips; `dart analyze --fatal-infos` reports no issues. Release assembly passed with the established Android lint exclusions; updated the existing Pixel_8 with the same package/signature and preserved app data. Visually checked the live owner account screen. Original Android Studio is open on `governorate_screen.dart`; simultaneous IDE/emulator operation is constrained by the 6 GB host.
- Five production-widget fixture previews are available in `../analysis/buyer-flow-five-screens.zip`; actual device account screenshot is `../analysis/new-flow-runtime-account.png`. Fixture previews use controlled test data and are labelled separately from device screenshots.

### Changed — 2026-10-27 — remaining Stitch screens

- Restyled the remaining 12 functional interfaces directly in the existing 10 Dart files: ID/selfie capture, verification waiting/result, purchase review, payment number/OTP/success, owner queue, QR scanner, customers, history and day details. Reused the cream palette, IBM Plex Arabic, white rounded cards, loaf/bread assets and pill actions; kept routes, controllers and service callbacks.
- Made camera/error/result screens, forms, metadata and owner actions scroll at narrow widths, large text and landscape. Kept camera-only capture and real scanner/redemption guards. Payment and verification remain the existing simulations; no new integration or real reservation was created for preview.
- Verified 161 selected visual/queue/payment/verification/a11y tests pass (2 pre-existing skips), with `dart analyze --fatal-infos` reporting no issues. Android release assembly passed after preserving/rebuilding a damaged Gradle transform cache; Android lint tasks were excluded by the existing environment workaround, and D8 Kotlin metadata warnings remain.
- Verified unchanged package/signing certificate, updated the existing Pixel_8 with `install -r --abi x86_64`, and visually checked the live owner queue. Original Android Studio project is open on `owner_queue_screen.dart`. Preserved existing Studio settings and used a fresh IDE system cache to avoid a stale socket lock. Device retains the established software-renderer launch flags.
- Review artifacts: `../analysis/remaining-runtime-owner-final.png` is a real AVD screenshot; `../analysis/raghif-remaining-screens.zip` contains production-widget test fixtures (including scanner camera-unavailable state), not device screenshots. Existing legacy “undo pickup” label still invokes the idempotent collect API; no reversal backend was introduced.

### Changed (Stitch application screens)

- Restyle the existing onboarding, registration, shared login, bakery list,
  bakery details, QR receipt, current order and owner dashboard with the
  cream Stitch palette, IBM Plex Arabic, loaf identity and rounded cards.
- Retain the existing authentication fields, search and availability guards,
  live order data, QR payload, receipt export and owner settings actions.
- Check production screens at phone, narrow/large-text and landscape sizes;
  verify focused behavior and accessibility checks, build the existing Android
  package and update it on the existing Pixel_8 without clearing application data.

### Changed (Stitch launch identity)

- Match the first Stitch splash design in the existing Flutter entrypoint:
  cream background, warm bread emblem, Arabic IBM Plex typography, wheat
  decoration, progress dots, and a pressed-state start button.
- Open the existing onboarding or authentication flow from the start button,
  and use matching cream/vector Android launch resources in light and dark mode.

### Changed (local Android setup)

- Use the Gradle 8.12 binary distribution instead of the full distribution.
  This keeps the build-tool version unchanged and avoids downloading its
  sources and documentation when setting up Android Studio.
- Limit Gradle memory and workers for the local emulator setup, and allow
  the existing Arabic Windows checkout path without moving the project.

### Changed (data source)

- **The server is the only source of data.** The on-device `drift` database
  is gone. Every screen now reads Supabase directly and updates live through
  Realtime. The signed-in user is the Supabase session, and the profile
  behind it is read from the server every time. Nothing about other users is
  stored on the phone.
- **One exception: the buyer's latest receipt is kept on the phone**, so the
  pickup QR still opens with no signal at the bakery. It is written only from
  a server answer, and cleared on sign-out or when the server says the order
  is gone.
- **Notifications come from the server only.** "Purchase confirmed" is now a
  push sent by `notify-batch` (new trigger on purchase insert, migration
  `20261003172252_notify_purchase_confirmed`). The phone no longer raises its
  own "purchase confirmed", "batch released" or OTP notifications. The mock
  login and payment codes are shown on screen, as before.
- `constitution.md` §I–II, `spec.md` and `README.md` record the change
  (ruling dated 2026-10-03).

### Fixed (sign-out)

- **Signing out from any screen lands on the login screen, with nothing
  behind it.** Signing out from the store list (a pushed screen) used to
  leave the store list on screen, with the login form hidden underneath it
  and reachable by pressing back. Crossing between signed in and signed out
  now clears every pushed screen, wherever it happens.
- **Signing out empties the on-device cache.** It held whatever the last
  account could see; for an owner, that included every buyer's name and
  national ID. The next account on the phone starts from its own data.

### Fixed (purchase cache)

- **Purchases deleted on the server now disappear from the phone.** The
  sync only ever added or replaced cached purchases, so a purchase removed
  server-side kept showing as "already bought today" until the app's data
  was cleared. Each pull now drops cached purchases the server no longer
  returns.

### Added (demo accounts)

- **Second demo buyer, حسن الخليلي** (`900444555`, PIN `1234`), in the login
  screen's demo sheet and the `seed-demo` account list, so two phones can
  test the queue at once (each account gets one bag a day).

### Fixed (release signing and config)

- **Release builds no longer ship with a throwaway debug key.** The release
  workflow used to fall back to the runner's debug key when the keystore
  secrets were missing; that key changes every run, so phones could not
  update over an earlier install. It now fails instead, and the signature
  check rejects any APK signed with the debug key.
- **Local release builds use the real keystore.** `storeFile` in
  `android/key.properties` is now resolved from `android/app/` (Flutter's
  documented layout), where the keystore actually lives. Before, the path
  never matched and local builds were silently debug-signed.
- **Supabase URL and anon key can be repo Variables.** The release workflow
  reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from repo variables first, then
  secrets. Both ship inside the APK, so they are not secret.

### Removed (CI)

- **Pixel golden tests are gone.** They failed on tiny rendering differences
  between machines (e.g. a 0.11% diff on the store list) and blocked PRs over
  UI changes, not broken behaviour. The widget and logic tests stay in CI.
  `test/goldens/test_fonts.dart` is kept because other tests use it.

### Fixed (release build)

- **The release APK now ships the real backend config and a real signature.**
  It was built from the dummy `.env.example` (so the app could not reach
  Supabase) and signed with the debug key. `release.yml` now writes `.env`
  from the `SUPABASE_URL` / `SUPABASE_ANON_KEY` secrets (failing if unset),
  signs with the `KEYSTORE_BASE64` / `KEYSTORE_PASSWORD` / `KEY_ALIAS` /
  `KEY_PASSWORD` secrets, and verifies the signature with `apksigner`.
  Installs signed with the old debug key must be uninstalled once first.

### Fixed (login errors)

- **A bad connection no longer reads as a wrong PIN or "not registered".**
  Every sign-in call swallowed all errors into `null`, so a phone with no
  signal was told its ID had no account and offered "create an account". The
  gateway's own 401/404 answers still mean "wrong PIN/code" and "unknown ID";
  anything else (no connection, a timeout, a 5xx) now surfaces as "could not
  reach the server, check your connection and try again", with the PIN field
  still there to retry.

### Added

- `constitution.md`: the project's non-negotiable rules, linked from the
  README. Its CI rule (VII) reflects the 2026-09-30 amendment: PRs run analyze
  + test, the APK is built once per merge.
- `.gitignore` covers the Supabase CLI's local link state and the local
  briefing documents folder.

### Changed (i18n)

- One string for "paid": `paidLabel` and `paidBadge` both held `مدفوع` and
  rendered the same chip, so a wording edit could leave one stale. `paidBadge`
  stays; buyer home uses it.

### Changed (CI)

- **PRs run analyze + test only; the APK is built once per merge.** The single
  `build` job used to analyze, test, build a release APK and upload it on every
  PR update and every master push, so each PR built an app nobody looked at and
  every merge repeated the PR's work. Now `ci.yml` (PRs) is `flutter analyze` +
  `flutter test` and `release.yml` (merge to master, or on demand) builds the
  arm64 APK and replaces the rolling `latest` release directly, with no
  artifact upload/download hop. Setup shared through
  `.github/actions/flutter`, Gradle caching through `setup-java`, and the
  Flutter pin moved to `environment.flutter` in `pubspec.yaml` so local,
  CI and release cannot disagree. The 180s shell timeout on the tests is gone
  (the job's 10-minute limit covers a hang; the suite takes ~2 minutes).
  Constitution VII amended accordingly (untracked file, 2026-09-30).

### Deployed

- 2026-09-30, project `mgmerkaokkffsypnkryj`: migration
  `lock_direct_writes` applied (recorded as `20260930130626`) and
  `auth-gateway` v14 deployed (seed-demo gated, OTP checked server-side).
  Verified against the live project: anonymous callers are refused on the
  owner RPCs, `select *` on `profiles` is refused for signed-in users while
  named columns work, the demo owner signs in, and the owner aggregates
  return. `SEED_DEMO_SECRET` is not set, so `seed-demo` is disabled; the
  database already holds the demo world.

### Fixed (sign-out)

- **Sign-out works when the server cannot be reached.** `logout()` awaited
  `signOut()`, which revokes the session on the server, so with the backend
  down it threw, the bloc never emitted `Unauthenticated`, and confirming
  the sign-out dialog did nothing. The revoke is best effort now and the
  remembered user is always cleared.

### Changed (login)

- **Login is one question per screen.** National ID, then PIN, then in.
  The first screen used to carry about nine competing things (a demo badge,
  logo, title and subtitle, a card, two alternative-login links, a create-
  account row and a demo-accounts card); it is now a field, a button and two
  quiet links. The PIN is the normal way in and the code by "SMS" is behind
  "forgot your PIN?" — previously the code was the default and the PIN a
  link on a screen you only reached after asking for a code. The fourth PIN
  digit signs you in. Demo accounts moved into a bottom sheet and sign in on
  one tap. An ID with no account is told so with "create an account" right
  beside it. System back goes back a step.
- **Fixed: a new phone could not use the code login at all.** Asking for a
  code first checked this device's cache for the user, so anyone with an
  existing account on a fresh install was told to create one. The server
  decides now.

### Fixed

- **Direct table writes are closed.** `purchases` and `scan_events` no longer
  accept inserts/updates from the app, so `reserve_bag` (sold-out, batch
  number, one bag a day) cannot be bypassed. `profiles.pin_hash` and `role`
  are no longer readable or writable by the app — the owner's device used to
  pull every buyer's bcrypt hash with `select *`; the sync now names its
  columns. Migration `20260930130626_lock_direct_writes`.
- **RPC rules moved into SQL.** `collect_purchase` refuses a batch that has
  not been called; `record_scan` only takes known outcomes and never links a
  purchase from another store; `save_store_allocation` locks the store row
  (no oversell race) and no longer takes `is_open` from the client's cache.
  The new RPCs are revoked from `anon`.
- **Failed writes are no longer silent.** Owner actions, the scanner and pin
  toggles report "did not happen" via `guardWrite` instead of leaving the
  scanner stuck; server errors reach the UI as `BackendUnavailableException`
  rather than raw driver errors, and only the exact sold-out message maps to
  `StoreSoldOutException`.
- **`auth-gateway`:** `seed-demo` is disabled unless the
  `SEED_DEMO_SECRET` function secret is set and sent as `x-seed-secret`;
  `otp-confirm` now checks the (mock) code server-side instead of minting a
  session from a national ID alone (`loginWithOtp` takes the entered code).
- Cache reads no longer invent facts (`batch_number ?? 1`, `createdAt = now`),
  and an upgrade from an install that stored the session id as an int no
  longer fails sign-in.
- SQL tests: `flutter/supabase/tests/run.sh` applies every migration to a
  throwaway Postgres (docker) and asserts the above as real roles.
- **Accessibility floor (constitution V), measured in `test/a11y`.** Body
  text is 16sp (was 15); field labels sit above the field at full size (the
  floating label shrank to ~12.75sp once you typed); input outlines are
  4.8:1 instead of 1.5:1; chip text on status tints is ~8:1; the demo rows
  are 48dp with 8dp between them; Arabic styles no longer set `letterSpacing`
  (it disables ligatures); the demo badge pads with `EdgeInsetsDirectional`.
  Registration lost its box-in-box field cards; the owner's pending-pickup
  count is a numeral, not a pill.
- **Fewer expensive accidents.** Signing out and closing the bakery ask
  first; the daily-bag stepper moves by 10.
- **Boot no longer waits on the network.** The first store pull is not
  awaited, so an unreachable backend shows the app instead of a permanent
  splash screen.

### Changed

- **Postgres is the source of truth; drift is a cache.** The app used to
  seed its own stores, buyers and queue on every install and decide the
  rules on-device, with Supabase wired in behind a `USE_SUPABASE` flag as
  a second opinion. That split is what let a receipt read "batch 4" while
  the server had the same row as batch 1. Now:
  - Every write is a Postgres RPC that authorizes itself
    (`reserve_bag`, `notify_next_batch`, `collect_purchase`,
    `set_store_open`, `record_scan`, `set_store_pinned`,
    `save_store_allocation`). The owner's customer book and sales history
    are computed in SQL.
  - The demo world is seeded server-side and idempotently by
    `seed_demo_buyers` / `seed_demo_stores` / `seed_demo_day`, driven by
    the `seed-demo` Edge Function action. `DemoContentSeeder` and the
    local `ensureSeeded()` calls are gone.
  - Ids are Supabase UUIDs everywhere — device, server and QR code. The
    local `INTEGER AUTOINCREMENT` ids and the `remote_id` mapping columns
    are gone, along with the `dynamic` id parameters and `_parseInt`
    coercion they forced on the controller.
  - **Writes require the backend** and fail loudly
    (`BackendUnavailableException`) instead of being applied locally and
    reconciled later. Reads still serve from cache while offline.
  - Drift schema v8 drops and recreates every table. There is no
    column-by-column upgrade from v7: the old ids named rows that only
    existed on one device, and a cache is cheap to refill.
  - QR payload is v2. **v1 receipts no longer scan** — they carry integer
    ids that identify nothing now, so they are rejected rather than
    resolved to whatever row shares the number.
  - Pickup is one-way: the old notified↔collected toggle is now
    `collectPurchase`. Bread that has been handed over cannot be
    un-handed, and the server offers no way back.
  - Removed as dead: the `dio`/`retrofit` scaffold that never had a server
    to talk to, the `useSupabase` flag, `pin_hash` from the local cache
    (PIN checks are the auth-gateway's job), and `AuthRepositoryImpl`.

### Fixed

- Push notifications — four defects found by tracing the live pipeline
  (trigger → pg_net → `notify-batch` → FCM) end to end:
  - **Duplicate batch alerts.** The Edge Function selected every purchase
    still sitting at `notified` for the store/day, so releasing batch 2
    re-alerted every uncollected buyer in batch 1, and batch 3 re-alerted
    batches 1 and 2. The trigger now sends `batchNumber` and the function
    filters on it. The trigger also joins the OLD transition table so it
    fires only for rows that actually crossed into `notified`, instead of
    any statement that happens to leave a row there.
  - **`notify-batch` was an open push relay.** `verify_jwt` is off (pg_net
    carries no session) and nothing else authenticated the caller, while
    store ids are world-readable — so anyone could alert every waiting
    buyer in any store. The trigger now sends a shared secret from Vault
    (generated by the migration, never committed) which the function
    verifies, failing closed when unset.
  - **Logout left the device subscribed.** `logout()` signed out without
    removing the row from `device_tokens`, so the handset kept receiving
    the previous user's batch pushes — the `auth.uid() = user_id` RLS
    policy means the delete has to happen *before* `signOut()`. Covered by
    a test that asserts the ordering.
  - **Backgrounded pushes used the wrong channel.** The Arabic
    `queue_notifications` channel was only applied to foreground messages,
    so OS-rendered pushes — the ones that matter — landed in Android's
    auto-created "Miscellaneous" channel at default importance. The channel
    is now created eagerly at startup, declared in AndroidManifest.xml as
    `default_notification_channel_id`, and named in the FCM payload.

  Requires a one-time `supabase secrets set NOTIFY_BATCH_SECRET=...` to the
  Vault value; until it is set the function rejects every call.

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

- Identity verification photos (ID photo + selfie) are now captured live with
  the camera — the selfie from the front camera, the ID from the rear. The
  gallery/picker path is deliberately gone: an uploaded image could be a photo
  of a photo or of someone else, which would defeat the identity check. A
  camera failure (permission denied, no camera app) now shows an Arabic error
  instead of a silent no-op.
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

- The "log in with your PIN instead" link on the sign-in screen no longer
  shows before a National ID is typed — PIN login is an alternate path for an
  identified user, so offering it on an empty form only added a dead end.
  Login golden regenerated.
- Buyer queue status chips ("تم الاستلام", "تم الإشعار") broke across two
  lines on a phone-width card, splitting the word mid-letter. The chip now
  keeps its intrinsic width and the pickup time wraps below it instead.
- Demo content is now seeded once per calendar day instead of once per
  install. Every queue read filters on today's date, so a build installed on
  one day showed an empty owner queue, dashboard and history the next — the
  seeder bailed out as soon as any purchase existed. Earlier days are kept,
  so the history screen gains real past days to browse, and the demo store's
  bags are restocked to its daily allocation each day.
- A closed bakery on the store list read "نفدت الكمية" (sold out), blaming
  the owner for stock they never put out. Closed stores now show "مغلق" on a
  neutral chip; sold-out keeps the red chip. Store list golden regenerated.
- Android launcher label was the latin placeholder "raghif"; it is now رغيف,
  matching the app's Arabic-only UI.
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
- Buyer home — "طلبي" (walkthrough P0 #2): the buyer now lands on their current
  order instead of the store list: live status (waiting → ready → collected,
  updating by itself), the paid badge, the batch number, and
  "اعرض وصل الاستلام" which reopens the pickup QR at any time. Until now the
  receipt only existed on the confirmation screen — leave it without saving and
  the ticket was gone. No ETA is shown: a time-to-next-batch needs a real
  owner-set batch schedule (decision C), so the screen stays honest with batch
  + status.
- Owner queue & dashboard polish (walkthrough P1 #6/#7):
  - every batch header now shows its tallies — تم الاستلام / بانتظار الاستلام /
    لم يُنادَ — so the owner sees who never showed up without counting rows.
  - "إشعار الدفعة التالية" asks for confirmation first, and the dialog warns how
    many buyers from earlier batches were called but never picked up (soft
    release-after-collected discipline: a hard block would deadlock the owner
    when someone simply never shows up).
  - the dashboard shows the live "بانتظار الاستلام" count (paid, not picked) and
    an in-app low-stock warning at ≤ 20 bags.

### Fixed

- Owner queue buyer rows overflowed (yellow/black stripes) once a row reached
  تم الإشعار / تم الاستلام: the confirm button took the width from the buyer
  info column, which then couldn't fit the status chip and time.
- Owner history page (walkthrough P0 #4): a day browser over the same queue the
  owner already works with. One grouped query per store gives each day's totals
  — sold, collected, and the end-of-day leftover (paid, never picked up) —
  newest day first; tapping a day lists its buyers with their status. Reached
  from a new "سجل المبيعات" button on the owner dashboard.
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

