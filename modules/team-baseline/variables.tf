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
}