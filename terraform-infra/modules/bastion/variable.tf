variable "instance_type" {
  description = "The instance type for the bastion host"
  type        = string
  default     = "t3.micro"
  
}

variable "key_name" {
  description = "The name of the key pair to use for the bastion host"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the bastion host in"
  type        = string
}

variable "security_group_id" {
  description = "The ID of the security group to associate with the bastion host"
  type        = string
}

variable "security_group_name" {
  description = "The name of the security group to associate with the bastion host"
  type        = string
}

variable "iam_instance_profile" {
  description = "The IAM instance profile to associate with the bastion host"
  type        = string
}