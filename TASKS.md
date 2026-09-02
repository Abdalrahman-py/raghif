# Raghif Flutter Port — Task Backlog

Open GitHub issues (prioritized p0 > p1 > p2) are the main task queue; this file
catches broader work that isn't issue-shaped. One item at a time, top to bottom.

Every push/PR is verified by Flutter CI (`.github/workflows/flutter-ci.yml`):
`flutter analyze`, `flutter test`, and a debug APK build must all pass.

Source of truth for *what* to build: `spec.md` (product + schema), `UI_SPEC.md` (design tokens).
The original Kotlin/Compose prototype under `app/` has been removed — the Flutter app is the
only implementation now (see #10).

## Backlog

- [x] Scaffold `flutter/` with `flutter create`, package name matching spec.md. Verify
      `flutter analyze` is clean. Commit.
- [x] Set up project structure (lib/features/..., clean-ish layout) and add the design tokens
      from `UI_SPEC.md` (colors, type scale, spacing) as a Flutter theme.
- [x] Define the local schema from `spec.md` as `drift` schema files (generated Dart types).
      Done in #19 — `drift` is the Dart-ecosystem equivalent of SQLDelight (which has no
      Dart/Flutter codegen target; see #4 for the full history).
- [x] Set up `drift` (drift_dev + sqlite3 driver) and wire local auth: phone + PIN login
      against the local `users` table, session persisted on-device. Done in #24 (and
      reworked with the domain/data layers in the Sep 2026 refactor).
- [x] Build the bread-queue list/pre-order screens per UI_SPEC.md, wired to mock data first.
      Done in #13.
- [ ] Replace mock data with real `drift` queries (#7, open).
- [ ] Add widget tests for the queue/pre-order flow (#8, open).
- [x] Add a `flutter build apk --debug` step to CI once the app builds cleanly.
      Done: Flutter CI (`flutter-ci.yml`) runs analyze + test + debug APK build on
      every push/PR.

## Notes

- Keep changes small and reviewable; check a box (or close an issue) only when the work
  is actually done and CI is green.
- CI pins Flutter to 3.41.6 (the version the project was created with — see the workflow
  comment). Before upgrading Flutter locally, bump the Android Gradle wrapper to >= 8.14
  and re-check AGP/Kotlin compatibility, or `flutter build apk` will fail.
- Prototype is LOCAL-ONLY: `drift` for persistence — the Dart-ecosystem equivalent of
  SQLDelight (SQLDelight itself is Kotlin/KMP-only and has no Dart/Flutter codegen target;
  no `sqldelight` package exists on pub.dev). See spec.md's Technical Decisions callout and
  issue #4 for the full history of this substitution. Never add Supabase or any hosted
  backend.
