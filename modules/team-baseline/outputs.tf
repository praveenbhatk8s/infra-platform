output "role_arn" {
  description = "ARN of the team's IAM role. This is what the team assumes."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the team's IAM role."
  value       = aws_iam_role.this.name
}

output "buckets" {
  description = "Map of short bucket name to its full name, ARN and visibility."
  value = {
    for k, b in local.buckets : k => {
      name       = aws_s3_bucket.this[k].bucket
      arn        = aws_s3_bucket.this[k].arn
      visibility = b.visibility
    }
  }
}