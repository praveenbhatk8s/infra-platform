#!/usr/bin/env bash
# Runs Terraform for exactly one team, against that team's own state file.
# Usage: scripts/tf-team.sh <plan|apply|destroy> <team>
# For destroy of a deleted team, set RESTORE_REF to a commit that still has its team.yaml.
set -euo pipefail

ACTION="${1:?usage: tf-team.sh <plan|apply|destroy> <team>}"
TEAM="${2:?usage: tf-team.sh <plan|apply|destroy> <team>}"
ENVIRONMENT="${ENVIRONMENT:-prod}"

ROOT="$(git rev-parse --show-toplevel)"
STACK="$ROOT/stacks/team"

if [[ "$ACTION" != "plan" && "$ACTION" != "apply" && "$ACTION" != "destroy" ]]; then
  echo "Action must be plan, apply or destroy, got: $ACTION" >&2
  exit 1
fi

if [[ ! "$TEAM" =~ ^[a-z][a-z0-9-]{1,18}[a-z0-9]$ ]]; then
  echo "Invalid team name: $TEAM" >&2
  exit 1
fi

# Offboarding: the team's folder is gone, but Terraform still needs its last
# team.yaml to know what to destroy. Restore it from an earlier commit.
if [[ "$ACTION" == "destroy" && ! -f "$ROOT/teams/$TEAM/team.yaml" ]]; then
  : "${RESTORE_REF:?RESTORE_REF must be set to destroy a deleted team}"
  mkdir -p "$ROOT/teams/$TEAM"
  git -C "$ROOT" show "$RESTORE_REF:teams/$TEAM/team.yaml" >"$ROOT/teams/$TEAM/team.yaml"
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

destroy=false
if [[ "$ACTION" == "destroy" ]]; then
  destroy=true
fi

terraform -chdir="$STACK" plan -destroy="$destroy" -input=false -lock-timeout=5m \
  -var "team=$TEAM" -var "environment=$ENVIRONMENT" \
  -out="$TEAM.tfplan"

if [[ "$ACTION" == "apply" || "$ACTION" == "destroy" ]]; then
  terraform -chdir="$STACK" apply -input=false -lock-timeout=5m "$TEAM.tfplan"
fi

if [[ "$ACTION" == "apply" ]]; then
  terraform -chdir="$STACK" apply -input=false -lock-timeout=5m "$TEAM.tfplan"
fi