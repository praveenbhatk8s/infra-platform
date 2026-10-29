variable "team" {
  description = "Team to deploy. Must match a folder under teams/."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region for the team's resources."
  type        = string
  default     = "eu-west-1"
}