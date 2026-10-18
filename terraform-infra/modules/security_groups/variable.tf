

variable "vpc_id" {
  description = "Vpc id"
  type = string
}

variable "environment" {
  description = "Environment name (e.g. dev)"
  type        = string
}

variable "project" {
  description = "Project name (e.g. goal-tracker)"
  type        = string
}

variable "tags" {
  description = "Tags added to every resource"
  type        = map(string)
  default     = {}
}

variable "alb_ingress_ports" {
  description = "Ports the public ALB accepts from the internet"
  type        = list(number)
  default     = [80,443]
}