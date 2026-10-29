mock_provider "aws" {}

variables {
  org_prefix             = "sumup"
  environment            = "prod"
  team_name              = "payments"
  cost_center            = "CC-1042"
  owner_email            = "payments-team@example.com"
  trusted_principal_arns = ["arn:aws:iam::123456789012:root"]
  buckets = [
    { name = "invoices", visibility = "private" },
    { name = "assets", visibility = "public" },
  ]
}

run "follows_naming_convention" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this["invoices"].bucket == "sumup-prod-payments-invoices"
    error_message = "Bucket names must follow <org>-<env>-<team>-<bucket>."
  }

  assert {
    condition     = aws_iam_role.this.name == "sumup-prod-payments"
    error_message = "Role name must follow <org>-<env>-<team>."
  }
}

run "private_bucket_blocks_all_public_access" {
  command = plan

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this["invoices"].block_public_acls,
      aws_s3_bucket_public_access_block.this["invoices"].ignore_public_acls,
      aws_s3_bucket_public_access_block.this["invoices"].block_public_policy,
      aws_s3_bucket_public_access_block.this["invoices"].restrict_public_buckets,
    ])
    error_message = "Private buckets must block every form of public access."
  }
}

run "public_bucket_is_read_only" {
  command = plan

  assert {
    condition = [
      for s in jsondecode(aws_s3_bucket_policy.this["assets"].policy).Statement : s.Action
      if s.Effect == "Allow"
    ] == ["s3:GetObject"]
    error_message = "A public bucket may only allow s3:GetObject."
  }
}

run "role_only_reaches_own_buckets" {
  command = plan

  assert {
    condition = toset(flatten([
      for s in jsondecode(aws_iam_role_policy.s3_access.policy).Statement : s.Resource
      ])) == toset([
      "arn:aws:s3:::sumup-prod-payments-invoices",
      "arn:aws:s3:::sumup-prod-payments-invoices/*",
      "arn:aws:s3:::sumup-prod-payments-assets",
      "arn:aws:s3:::sumup-prod-payments-assets/*",
    ])
    error_message = "The role may only reference this team's own buckets."
  }
}

run "rejects_unknown_visibility" {
  command = plan

  variables {
    buckets = [{ name = "data", visibility = "internal" }]
  }

  expect_failures = [var.buckets]
}