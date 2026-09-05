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

