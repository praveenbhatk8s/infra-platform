mock_provider "aws" {}

run "plans_payments_from_its_team_file" {
  command = plan

  variables {
    team = "payments"
  }

  assert {
    condition     = module.team.buckets["invoices"].name == "sumup-prod-payments-invoices"
    error_message = "The stack must build the team's buckets from teams/payments/team.yaml."
  }
}