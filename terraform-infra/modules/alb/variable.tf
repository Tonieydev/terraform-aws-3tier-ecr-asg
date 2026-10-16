variable "environment" { type = string }
variable "project"     { type = string }

variable "tier" {
  type        = string
  description = "frontend or backend. Used in resource names."
}

variable "internal" {
  type    = bool
  default = false
}

variable "vpc_id"            { type = string }
variable "security_group_id" { type = string }

variable "subnet_ids" {
  type = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "An ALB needs subnets in at least 2 AZs."
  }
}

variable "target_group_port" {
  type        = number
  description = "Port the application listens on."
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "stickiness_enabled" {
  type    = bool
  default = false
}

variable "enable_https" {
  type    = bool
  default = false
}

variable "certificate_arn" {
  type    = string
  default = null
}

variable "enable_deletion_protection" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}