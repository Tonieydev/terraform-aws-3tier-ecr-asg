variable "instance_type" {
  description = "ec2 instance type"
  type = string
  default = "t3.micro"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group."
  type        = list(string)
}
variable "min_size" {
  description = "Minimum size of the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group."
  type        = number
  default     = 5
}

variable "desired_size" {
  description = "desired size"
  type = number
  default = "2"
}

variable "target_group_arns" {
  type    = list(string)
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "project" {
  description = "Project name (e.g. goal-tracker)"
  type        = string
}

variable "region" {
  description = "AWS region, used for ECR login and CloudWatch logs"
  type        = string
}

variable "tags" {
  description = "Tags added to every resource"
  type        = map(string)
  default     = {}
}

variable "iam_instance_profile" {
  description = "The name of the IAM instance profile to associate with the EC2 instances."
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the EC2 instances."
  type        = list(string)
}


variable "backend_internal_url" {
  description = "The internal URL of the backend service."
  type        = string
}


variable "alarm_actions" {
 description = "A list of ARNs for the actions to execute when the alarm state is reached."
  type        = list(string)
}

variable "docker_image" {
  description = "Full ECR image URI including tag (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/dev-goal-tracker-backend:a1b2c3d)."
  type        = string
}

variable "ecr_registry" {
  description = "ECR registry host used for docker login (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com)."
  type        = string
}


variable "db_secret_arn" {
  description = "ARN of the RDS-managed secret holding the master username and password."
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
  description = "Database name"
  type        = string
}