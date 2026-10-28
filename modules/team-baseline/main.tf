locals {
  name_prefix = "${var.org_prefix}-${var.environment}-${var.team_name}"

  # The naming convention lives here and nowhere else:
  #   <org>-<env>-<team>-<bucket>   e.g. sumup-prod-payments-invoices
  buckets = {
    for b in var.buckets : b.name => {
      name       = "${local.name_prefix}-${b.name}"
      visibility = b.visibility
    }
  }
}

resource "aws_s3_bucket" "this" {
  for_each = local.buckets

  bucket = each.value.name

  # Never delete data implicitly: destroying a non-empty bucket fails on purpose.
  force_destroy = false
}