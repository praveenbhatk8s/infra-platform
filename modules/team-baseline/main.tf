locals {
  name_prefix = "${var.org_prefix}-${var.environment}-${var.team_name}"

  # The naming convention lives here and nowhere else:
  #   <org>-<env>-<team>-<bucket>   e.g. sumup-prod-payments-invoices
    buckets = {
    for b in var.buckets : b.name => {
      name       = "${local.name_prefix}-${b.name}"
      visibility = b.visibility
      public     = b.visibility == "public"
      arn        = "arn:aws:s3:::${local.name_prefix}-${b.name}"
    }
  }
}

resource "aws_s3_bucket" "this" {
  for_each = local.buckets

  bucket = each.value.name

  # Never delete data implicitly: destroying a non-empty bucket fails on purpose.
  force_destroy = false
}

# ACLs disabled on every bucket: access is controlled by policies only.
resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}