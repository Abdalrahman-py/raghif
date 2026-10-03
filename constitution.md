# Raghif Constitution

Non-negotiable principles for this repo. Everything else — specs, tasks, code —
is negotiable and changes often. This file changes rarely, and only on the
record (see Governance).

Context that makes these rules non-negotiable: Raghif rations subsistence food
in Gaza. A double-booked bag, a lost reservation or an unreadable screen is not
a bug report — it is someone who walked to a market for nothing.

---

## I. Postgres decides, the device asks

Supabase Postgres is the single source of truth and the only source of data.
The app keeps no local database: every screen reads Postgres (scoped by RLS)
and stays current through Realtime. Who is signed in is the Supabase session;
the profile behind it is read from the server every time.

- No business fact is ever created locally first. Reservations, batch numbers,
  allocations and remaining counts come from the server or they do not exist.
- One exception, kept on purpose: the signed-in buyer's latest receipt is
  saved on the phone, written only from a server answer, so the pickup QR
  still opens with no signal at the bakery. It is cleared on sign-out and
  whenever the server says that order is gone.
- Every notification is a server push (the `notify-batch` Edge Function). The
  app raises none of its own.
- Ids are server-generated UUIDs, stored verbatim. The same id means the same
  row on the device, on the server and in a QR code. No local autoincrement,
  no client/server id mapping.

## II. Writes require the backend, and say so when they fail

A write that did not reach Postgres did not happen.

- Writes fail loudly (`BackendUnavailableException`) and the UI tells the user.
- No optimistic local write with later reconciliation. That is how two buyers
  end up holding the last bag.
- Reads go to the server too. With no connection a screen shows nothing new
  rather than something stale; the saved receipt is the only exception.

## III. Business rules live in SQL

Rules are enforced where they cannot be bypassed, not where they are convenient.

- One bag per national ID per day, across all stores — a database constraint,
  not a client check.
- Sold-out checks, batch assignment, allocation changes and owner aggregates
  are RPCs (`SECURITY DEFINER`) or SQL, never client arithmetic.
- Every table has RLS. Every RPC authorizes its own caller.
- The service-role key never ships in the app. Service-role work happens in
  Edge Functions.
- A client-side check is a UX affordance, never the enforcement.

## IV. Identity data is dangerous

National ID, phone number and PIN are the most sensitive things this app holds,
in a place where lists of people carry real risk.

- Never logged, never in analytics, never in an error message that leaves the
  device, never in a URL.
- PINs are bcrypt-hashed server-side (pgcrypto). No plain or home-rolled hashes.
- A buyer's row is visible to that buyer and to the owner of the store they
  bought from. Nobody else, by RLS, not by query discipline.

## V. Accessibility is the product

Target: cheap Android phones, outdoor sunlight, older and low-literacy users,
no training beyond the on-site pilot. The floors below are hard.

- Body text ≥ 16sp (17sp default); no text below 15sp.
- Touch targets ≥ 48×48dp, ≥ 8dp apart.
- Status is never signalled by color alone — always color **plus** icon or
  text. Must survive a grayscale screen in the sun.
- Contrast to the `UI_SPEC.md` tokens; those tokens are the palette, not a
  starting suggestion.
- Arabic-only, RTL. No English strings in the UI, no hardcoded LTR layout
  assumptions, no bilingual toggle work until the owner says otherwise
  (ruling 2026-09-06).
- No motion-forward UI. Low-end devices pay for it.

## VI. Mocks announce themselves

Jawwal Pay and the SMS gateway are unresolved external dependencies. The
prototype simulates them.

- A simulated flow is visibly simulated in the UI (the OTP is shown on screen —
  it is not pretending an SMS was sent).
- No mock ever writes a fact that a real integration would later contradict —
  no fake "paid" state, no fake delivery receipt.
- Demo data is seeded **server-side** (`seed_demo_*`), never by each install.

## VII. Green CI or it is not done

`.github/workflows/ci.yml`: `flutter analyze` and `flutter test` pass on every
PR. The APK is built once per merge to `master` (`release.yml`), not on every
PR — a PR's APK was built, uploaded and never used. (Amended 2026-09-30: this
used to require the APK build on every push and PR.)

- Non-trivial logic ships with a test. Repository, sync, RPC-boundary and
  QR-decode logic are non-trivial by default.
- Tests do not leak database connections or streams; the CI timeout exists
  because they once did.
- Flutter is pinned to 3.41.6, in one place: `environment.flutter` in
  `flutter/pubspec.yaml`, which CI and the release build read. Bumping it means
  bumping the Gradle wrapper (≥ 8.14) and re-checking AGP/Kotlin first — in the
  same change.

## VIII. Branches only, `master` by PR

Agreed 2026-09-06, still binding.

- Branch off `master`. Small, reviewable commits. Never push to `master`,
  never merge into it locally. `master` moves only through reviewed PRs.
- When `master` gains code, merge or rebase it into the working branch.
- `CHANGELOG.md` is updated **before** the commit it describes.
- Secrets live in `.env` (gitignored). `.env.example` stays in sync so a fresh
  checkout and CI can build.

## IX. Build for one pilot store

Scope discipline is a safety property here, not a preference. The plan is one
store, on-site, learning the collection workflow in person.

- No feature without a rule in `spec.md` behind it.
- No abstraction for a second backend, a second language, a payments provider
  or a store count we do not have.
- Deleting code is progress. The Kotlin prototype and the `dio`/`retrofit`
  scaffold were both removed on purpose; keep it that way.

---

## Authority

What to build: `spec.md` (product + schema) and `UI_SPEC.md` (design system).
What to build next: open GitHub issues, then `TASKS.md`.

When they disagree, the **most recent dated ruling wins** and the stale wording
is a known-stale owner file, not a requirement. Current live corrections:

| Ruling | Date | Overrides |
|---|---|---|
| Arabic-only, no bilingual work | 2026-09-06 | "Bilingual AR/EN" in `spec.md`, `README.md`, `UI_SPEC.md` |
| One bag per national ID per day, all stores | 2026-09-06 | "per store per day" in `README.md` |
| Supabase is the backend; `drift` is a permanent cache | 2026-09-19 | "local-only, never add Supabase" in `TASKS.md` |
| Supabase is the only data source: no `drift` cache, the buyer's receipt excepted; notifications are server pushes only | 2026-10-03 | The 2026-09-19 ruling above, and "drift as permanent offline cache" in `spec.md` |

## Governance

This file outranks habit, convenience and any agent's default behaviour. Code
that violates it does not merge, however well it works.

Amending it: state the principle changed, the date, and why, in the PR that
changes it — and update the stale document it supersedes in the same PR. An
undocumented amendment is not one.
