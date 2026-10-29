#!/usr/bin/env bash
# Prints the teams a change touches, as a JSON array: ["payments","risk"]
# Usage: scripts/detect-changes.sh <base-commit> <head-commit>
set -euo pipefail

BASE="${1:?usage: detect-changes.sh <base-commit> <head-commit>}"
HEAD="${2:?usage: detect-changes.sh <base-commit> <head-commit>}"
cd "$(git rev-parse --show-toplevel)"

changed_files="$(git diff --name-only "$BASE" "$HEAD")"

if grep -qE '^(modules|stacks)/' <<<"$changed_files"; then
  # Platform code changed: every team is affected.
  candidates="$(ls teams)"
else
  # Only the teams whose own folder changed.
  candidates="$(grep -oE '^teams/[^/]+' <<<"$changed_files" | cut -d/ -f2 | sort -u || true)"
fi

# Keep teams that still exist (a deleted team is offboarding, not a plan).
for team in $candidates; do
  if [[ -f "teams/$team/team.yaml" ]]; then
    echo "$team"
  fi
done | jq -Rnc '[inputs]'