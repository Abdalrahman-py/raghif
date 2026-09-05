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

### Fixed

- Owner allocation save no longer resets today's remaining bags to the full
  daily limit, wiping out bags already sold before the save.
- Buying a bag after a store sells out is now rejected instead of silently
  clamping remaining stock to zero and completing the purchase anyway.
- Logging back in after registration/onboarding no longer leaves the stale
  login screen on top of the app.
- Registering with a phone number or national ID already on file now shows
  an Arabic message instead of a raw database exception.
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

- Store owners can now set today's purchase window (start/end time), shown
  to buyers on the store list and purchase screen alongside the existing
  bags-remaining count.
- Notifying the next batch now fires a real OS notification, simulating the
  push notification a buyer would get in production — there's no backend
  in this prototype, so it fires directly on whatever device runs the
  owner's "Notify Next Batch" action. Uses `flutter_local_notifications`
  (previously an unused dependency); no-op on web.

