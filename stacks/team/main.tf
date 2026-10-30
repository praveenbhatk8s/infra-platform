provider "aws" {
  region = var.aws_region
}

locals {
  config = yamldecode(file("${path.module}/../../teams/${var.team}/team.yaml"))
}

resource "terraform_data" "team_name_guard" {
  input = var.team

  lifecycle {
    precondition {
      condition     = local.config.team == var.team
      error_message = "teams/${var.team}/team.yaml says team \"${local.config.team}\". It must match its folder name."
    }
  }
}

module "team" {
  source = "../../modules/team-baseline"

  org_prefix             = "sumup"
  environment            = var.environment
  team_name              = local.config.team
  cost_center            = local.config.cost_center
  owner_email            = local.config.owner
  trusted_principal_arns = local.config.trusted_principals
  buckets                = local.config.buckets
}