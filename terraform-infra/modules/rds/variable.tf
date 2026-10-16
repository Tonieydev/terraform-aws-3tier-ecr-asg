variable "environment" {
  type = string
}

variable "project" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "subnet_ids" {
  type        = list(string)
  description = "Database subnet IDs, one per AZ."

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Multi-AZ needs database subnets in at least 2 AZs."
  }
}

variable "security_group_id" {
  type        = string
  description = "Database security group. Allow 5432 from the backend security group only."
}

variable "engine_version" {
  type        = string
  default     = "15"
  description = "Postgres major version. Must match the parameter group family (postgres15)."
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "monitoring_interval" {
  type        = number
  default     = 0
  description = "Enhanced Monitoring interval in seconds. 0 disables it."

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be 0, 1, 5, 10, 15, 30, or 60."
  }
}