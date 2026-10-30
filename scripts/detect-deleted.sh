#!/usr/bin/env bash
# Prints teams whose team.yaml was deleted, as a JSON array: ["risk"]
# Usage: scripts/detect-deleted.sh <base-commit> <head-commit>
set -euo pipefail

BASE="${1:?usage: detect-deleted.sh <base-commit> <head-commit>}"
HEAD="${2:?usage: detect-deleted.sh <base-commit> <head-commit>}"
cd "$(git rev-parse --show-toplevel)"

git diff --name-only --diff-filter=D "$BASE" "$HEAD" -- 'teams/*/team.yaml' |
  cut -d/ -f2 |
  jq -Rnc '[inputs | select(length > 0)]'