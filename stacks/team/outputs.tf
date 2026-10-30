output "role_arn" {
  description = "The team's IAM role."
  value       = module.team.role_arn
}

output "buckets" {
  description = "The team's buckets."
  value       = module.team.buckets
}