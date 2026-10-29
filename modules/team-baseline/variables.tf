variable "team_name" {
  description = "Team identifier, used in resource names and tags."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}[a-z0-9]$", var.team_name))
    error_message = "team_name must be 3-20 chars: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "buckets" {
  description = "Buckets the team needs. Every bucket must set visibility explicitly."
  type = list(object({
    name       = string
    visibility = string
  }))

  validation {
    condition     = length(var.buckets) >= 1
    error_message = "Each team must declare at least one bucket."
  }

  validation {
    condition     = alltrue([for b in var.buckets : contains(["public", "private"], b.visibility)])
    error_message = "Every bucket must set visibility to exactly \"public\" or \"private\"."
  }

  validation {
    condition     = length(distinct([for b in var.buckets : b.name])) == length(var.buckets)
    error_message = "Bucket names must be unique within a team."
  }

  validation {
    condition     = alltrue([for b in var.buckets : can(regex("^[a-z0-9][a-z0-9-]{1,18}[a-z0-9]$", b.name))])
    error_message = "Bucket names must be 3-20 chars: lowercase letters, digits and hyphens, not starting or ending with a hyphen."
  }
}

variable "org_prefix" {
  description = "Organisation prefix for every resource name. Set by the platform, not by teams."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,9}$", var.org_prefix))
    error_message = "org_prefix must be 2-10 chars: lowercase letters and digits, starting with a letter."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "trusted_principal_arns" {
  description = "IAM principals allowed to assume the team role, e.g. the team's SSO role."
  type        = list(string)

  validation {
    condition     = length(var.trusted_principal_arns) >= 1
    error_message = "At least one trusted principal is required, otherwise nobody can use the role."
  }
}

variable "cost_center" {
  description = "Cost center the team's spend is charged to."
  type        = string

  validation {
    condition     = length(trimspace(var.cost_center)) > 0
    error_message = "cost_center must not be empty."
  }
}

variable "owner_email" {
  description = "Team contact, ideally a distribution list rather than a person."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.owner_email))
    error_message = "owner_email must be a valid email address."
  }
}