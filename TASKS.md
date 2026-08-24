# Raghif Flutter Port — Task Backlog

Consumed by `.github/workflows/flutter-loop.yml` (runs every 6h). The loop checks open GitHub
issues first (label `flutter-port`, or any open issue if that label isn't in use yet) — this
file is the **fallback** when no issues are open. One unchecked task per run, top to bottom.
Check a box, commit, stop — don't chain multiple tasks in one run.

Source of truth for *what* to build: `spec.md` (product + schema), `UI_SPEC.md` (design tokens).
The Kotlin app under `app/` is a throwaway prototype — reference it for behavior, don't port its
structure.

## Backlog

- [x] Scaffold `flutter/` with `flutter create`, package name matching spec.md, min SDK per
      current `app/build.gradle.kts`. Verify `flutter analyze` is clean. Commit.
- [x] Set up project structure (lib/features/..., clean-ish layout) and add the design tokens
      from `UI_SPEC.md` (colors, type scale, spacing) as a Flutter theme.
- [x] Define the local schema from `spec.md` as SQLDelight `.sq` files (generated Dart types).
- [ ] Set up SQLDelight (plugin + sqlite driver) and wire local auth: phone + PIN login
      against the local `users` table, session persisted on-device.
- [ ] Build the bread-queue list/pre-order screens per UI_SPEC.md, wired to mock data first.
- [ ] Replace mock data with real SQLDelight queries.
- [ ] Add widget tests for the queue/pre-order flow.
- [ ] Add a `flutter build apk --debug` step to CI once the app builds cleanly (needs Android
      SDK setup in the workflow — not yet added, keep loop on `flutter analyze`/`flutter test`
      until this task).

## Notes for the loop

- **SQLDelight has no Dart codegen target** (it's Kotlin/JVM/KMP-only) — the schema task used
  [`drift`](https://pub.dev/packages/drift) instead, the Dart-ecosystem package built as
  SQLDelight's equivalent (declarative SQL schema file, compile-time-checked queries, generated
  type-safe Dart API). Schema lives in `flutter/lib/data/local/database.drift`, mirroring
  spec.md's table definitions. Treat every remaining "SQLDelight" mention in this backlog (and
  in spec.md) as meaning drift/on-device sqlite — don't try to add real SQLDelight tooling.
- If `flutter/` doesn't exist yet, the first task (scaffold) is always next regardless of
  checkboxes above it — don't skip ahead.
- If a task fails (analyze/test red), fix it in the same run rather than checking the box.
- Keep runs small. A half-finished screen committed with a clear TODO comment beats an
  uncommitted large diff lost when the run ends.
- Prototype is LOCAL-ONLY: SQLDelight for persistence. Never add Supabase, httpSMS, or any
  hosted backend.
