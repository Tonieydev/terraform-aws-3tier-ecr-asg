locals {
  name_prefix = "${var.environment}-${var.project}"

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

variable "region" {
  description = "AWS region for every resource."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name, used in resource names and tags."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name, used in resource names and tags."
  type        = string
  default     = "goal-tracker"
}

variable "availability_zones" {
  description = "Two AZs in the selected region."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ---------------------------------------------------------------- Network

variable "single_nat_gateway" {
  description = "One NAT gateway for both AZs. Saves cost; loses AZ redundancy for outbound traffic."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------- Release

variable "image_tag" {
  description = "Image tag to deploy. Written by deploy.sh to image_tag.auto.tfvars."
  type        = string

  validation {
    condition     = var.image_tag != "latest"
    error_message = "Use a versioned tag, not latest."
  }
}

# ---------------------------------------------------------------- Frontend tier

variable "frontend_instance_type" {
  description = "EC2 instance type for the frontend tier."
  type        = string
  default     = "t3.micro"
}

variable "frontend_capacity" {
  description = "Frontend ASG capacity."
  type = object({
    min     = number
    desired = number
    max     = number
  })
  default = { min = 2, desired = 2, max = 5 }

  validation {
    condition     = var.frontend_capacity.min <= var.frontend_capacity.desired && var.frontend_capacity.desired <= var.frontend_capacity.max
    error_message = "Frontend capacity must satisfy min <= desired <= max."
  }
}

# ---------------------------------------------------------------- Backend tier

variable "backend_instance_type" {
  description = "EC2 instance type for the backend tier."
  type        = string
  default     = "t3.micro"
}

variable "backend_capacity" {
  description = "Backend ASG capacity."
  type = object({
    min     = number
    desired = number
    max     = number
  })
  default = { min = 2, desired = 2, max = 5 }

  validation {
    condition     = var.backend_capacity.min <= var.backend_capacity.desired && var.backend_capacity.desired <= var.backend_capacity.max
    error_message = "Backend capacity must satisfy min <= desired <= max."
  }
}

variable "backend_health_check_path" {
  description = "Backend path the ALB health check calls. Must return 200."
  type        = string
  default     = "/goals"
}

# ---------------------------------------------------------------- Database

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "goals"
}

variable "db_username" {
  description = "Master username. The password is generated and stored in Secrets Manager by RDS."
  type        = string
  default     = "goals_admin"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_multi_az" {
  description = "Standby replica in the second AZ. Roughly doubles RDS cost."
  type        = bool
  default     = true
}

variable "db_protect" {
  description = "Deletion protection and final snapshot. Keep false for a disposable test stack so destroy works cleanly."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------- Alerts

variable "alarm_actions" {
  description = "SNS topic ARNs notified by CloudWatch alarms. Empty disables notifications."
  type        = list(string)
  default     = []
}

variable "alb_ingress_ports" {
  description = "Ports the public ALB accepts from the internet"
  type        = list(number)
  default     = [80,443]
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}