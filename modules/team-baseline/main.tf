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

  tags = {
    "team"        = var.team_name
    "cost-center" = var.cost_center
    "owner"       = var.owner_email
    "environment" = var.environment
    "managed-by"  = "terraform"
  }
}

resource "aws_s3_bucket" "this" {
  for_each = local.buckets

  bucket = each.value.name

  # Never delete data implicitly: destroying a non-empty bucket fails on purpose.
  force_destroy = false

  tags = merge(local.tags, { "visibility" = each.value.visibility })
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

# Private: everything blocked.
# Public:  ACLs still blocked; only a bucket policy (written below) may grant access.
resource "aws_s3_bucket_public_access_block" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = !each.value.public
  restrict_public_buckets = !each.value.public
}

resource "aws_s3_bucket_policy" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [each.value.arn, "${each.value.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      }],
      each.value.public ? [{
        Sid       = "PublicReadObjects"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${each.value.arn}/*"
      }] : []
    )
  })

  # The public access block must be relaxed before AWS accepts a public policy.
  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_iam_role" "this" {
  name = local.name_prefix

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = var.trusted_principal_arns }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy" "s3_access" {
  name = "s3-team-buckets"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListOwnBuckets"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [for b in local.buckets : b.arn]
      },
      {
        Sid      = "ReadWriteOwnObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [for b in local.buckets : "${b.arn}/*"]
      },
    ]
  })
}