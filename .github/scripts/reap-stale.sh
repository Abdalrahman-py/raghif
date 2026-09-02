#!/usr/bin/env bash
# Loop reaper: reset issues stuck in `ai-in-progress` with no open PR.
# A run that dies (Claude rate limit, timeout, crash) leaves its issue locked in
# `ai-in-progress` forever — this resets it to `ai-ready` so the next run retries.
#
# Usage: bash reap-stale.sh   (GH_TOKEN or `gh auth token` must be available)
# Env:   THRESHOLD_MIN  — min age in minutes before an issue counts as stale (default 120)
#         REPO           — owner/name (default: GITHUB_REPOSITORY or Abdalrahman-py/raghif)
set -euo pipefail

REPO="${REPO:-${GITHUB_REPOSITORY:-Abdalrahman-py/raghif}}"
THRESHOLD_MIN="${THRESHOLD_MIN:-120}"
export GH_TOKEN="${GH_TOKEN:-$(gh auth token)}"

echo "Reaping issues stuck in ai-in-progress for > ${THRESHOLD_MIN}m ($REPO)"

for n in $(gh issue list --repo "$REPO" --state open --label ai-in-progress --json number --jq '.[].number'); do
  updated=$(gh api "repos/$REPO/issues/$n" --jq '.updated_at')
  age_min=$(( ( $(date +%s) - $(date -d "$updated" +%s) ) / 60 ))
  # Skip if an open PR still claims it (loop merges its own PR before finishing, so an
  # open one here means the run died mid-way, e.g. auto-merge failed on conflicts)
  claimed=$(n="$n" gh pr list --repo "$REPO" --state open --json number,body \
    --jq '[.[] | select(.body | test("closes #" + env.n + "\\b"; "i"))] | length')

  if [ "$age_min" -gt "$THRESHOLD_MIN" ] && [ "$claimed" -eq 0 ]; then
    gh issue edit "$n" --repo "$REPO" --remove-label ai-in-progress --add-label ai-ready
    gh issue comment "$n" --repo "$REPO" --body "Loop reaper: sat in \`ai-in-progress\` too long with no open PR — the run that picked this up likely died (Claude rate limit / timeout). Reset to \`ai-ready\`; the next loop run will retry."
    echo "RESET  #$n (age ${age_min}m)"
  else
    echo "KEEP   #$n (age ${age_min}m, claimed=$claimed)"
  fi
done

echo "Reap done."
