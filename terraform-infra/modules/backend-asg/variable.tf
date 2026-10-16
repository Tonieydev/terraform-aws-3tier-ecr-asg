variable "instance_type" {
  description = "instacne type"
  type = string
  default = "t3.micro"
}

variable "max_size" {
  description = "max size of the ASG"
  type = number
  default = 5
}

variable "min_size" {
  description = "min size of the ASG"
  type = number
  default = 2
}

variable "desired_size" {
  description = "desired size of the ASG"
  type = number
  default = 3
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type = string
}

variable "security_group_ids" {
  description = "Security group ID"
  type = list(string)
}

variable "tags" {
  type = map(string)
  description = "tags"
}

variable "subnet_ids" {
  description = "subnet ids"
  type = list(string)
}

variable "environment" {
  description = "Environment name"
  type = string
}

variable "project" {
  description = "Project name"
  type = string
}

variable "alarm_actions" {
  description = "alarm actions"
  default = []
  type = list(string)
}

variable "target_group_arns" {
  description = "traget group arn"
  type = list(string)
}


variable "db_secret_arn" {
  description = "ARN of Secrets Manager secret containing database credentials"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "docker_image" {
  description = "Full ECR image URI including tag (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/dev-goal-tracker-backend:a1b2c3d)."
  type        = string
}

variable "ecr_registry" {
  description = "ECR registry host used for docker login (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com)."
  type        = string
}

variable "db_host" {
  description = "RDS endpoint address (host only, no port)."
  type        = string
}

variable "db_port" {
  description = "RDS port."
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name."
  type        = string
}
