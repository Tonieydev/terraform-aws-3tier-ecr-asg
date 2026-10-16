variable "environment" {
  description = "Environment name, used as the repository name prefix (e.g. dev)."
  type        = string
}

variable "project" {
  description = "Project name, used in repository names (e.g. goal-tracker)."
  type        = string
}

variable "repositories" {
  description = "Components that each get a repository. Names become <environment>-<project>-<component>."
  type        = list(string)
  default     = ["backend", "frontend"]

  validation {
    condition     = length(var.repositories) > 0 && alltrue([for r in var.repositories : can(regex("^[a-z0-9][a-z0-9-]*$", r))])
    error_message = "Each repository must be lowercase letters, digits or hyphens, and start with a letter or digit."
  }
}

variable "force_delete" {
  description = "Delete repositories on destroy even when they still contain images."
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Number of most recent images to keep per repository. Older images are expired."
  type        = number
  default     = 20

  validation {
    condition     = var.max_image_count >= 1
    error_message = "max_image_count must be at least 1."
  }
}

variable "untagged_expiry_days" {
  description = "Days after which untagged images are expired."
  type        = number
  default     = 1

  validation {
    condition     = var.untagged_expiry_days >= 1
    error_message = "untagged_expiry_days must be at least 1."
  }
}

variable "tags" {
  description = "Additional tags applied to every repository."
  type        = map(string)
  default     = {}
}
