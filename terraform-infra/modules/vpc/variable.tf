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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs to spread subnets across, one subnet per tier per AZ"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidr" {
  description = "Public subnets: external ALB and NAT gateway"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "frontend_private_subnet" {
  description = "Private subnets for frontend instances"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "backend_private_subnet" {
  description = "Private subnets for the internal ALB and backend instances"
  type        = list(string)
  default     = ["10.0.5.0/24", "10.0.6.0/24"]
}

variable "database_private_subnet" {
  description = "Private subnets for RDS"
  type        = list(string)
  default     = ["10.0.7.0/24", "10.0.8.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) so private instances can reach the internet"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "One NAT gateway shared by all AZs instead of one per AZ"
  type        = bool
  default     = false
}