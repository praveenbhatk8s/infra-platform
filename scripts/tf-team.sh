#!/usr/bin/env bash
# Runs Terraform for exactly one team, against that team's own state file.
# Usage: scripts/tf-team.sh <plan|apply> <team>
set -euo pipefail

ACTION="${1:?usage: tf-team.sh <plan|apply> <team>}"
TEAM="${2:?usage: tf-team.sh <plan|apply> <team>}"
ENVIRONMENT="${ENVIRONMENT:-prod}"

ROOT="$(git rev-parse --show-toplevel)"
STACK="$ROOT/stacks/team"

if [[ "$ACTION" != "plan" && "$ACTION" != "apply" ]]; then
  echo "Action must be plan or apply, got: $ACTION" >&2
  exit 1
fi

if [[ ! "$TEAM" =~ ^[a-z][a-z0-9-]{1,18}[a-z0-9]$ ]]; then
  echo "Invalid team name: $TEAM" >&2
  exit 1
fi

if [[ ! -f "$ROOT/teams/$TEAM/team.yaml" ]]; then
  echo "No such team: teams/$TEAM/team.yaml" >&2
  exit 1
fi

# A separate .terraform folder per team, so one team's backend settings
# can never carry over to another team.
export TF_DATA_DIR="$STACK/.terraform-$TEAM"

terraform -chdir="$STACK" init -input=false \
  -backend-config=backend.hcl \
  -backend-config="key=$ENVIRONMENT/teams/$TEAM/terraform.tfstate"

terraform -chdir="$STACK" plan -input=false -lock-timeout=5m \
  -var "team=$TEAM" -var "environment=$ENVIRONMENT" \
  -out="$TEAM.tfplan"

if [[ "$ACTION" == "apply" ]]; then
  terraform -chdir="$STACK" apply -input=false -lock-timeout=5m "$TEAM.tfplan"
fi