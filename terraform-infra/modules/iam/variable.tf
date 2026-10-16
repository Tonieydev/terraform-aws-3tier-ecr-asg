variable "environment" { type = string }
variable "project"     { type = string }

variable "secret_arns" {
  description = "Secrets the instances may read."
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}