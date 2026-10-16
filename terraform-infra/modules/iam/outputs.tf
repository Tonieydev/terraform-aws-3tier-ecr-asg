output "ec2_role_arn" {
  value       = aws_iam_role.ec2_role.arn
  description = "The ARN of the IAM role for EC2 instances."
}

output "ec2_profile_arn" {
  value       = aws_iam_instance_profile.ec2_instance_profile.arn
  description = "The ARN of the IAM instance profile for EC2 instances."
}

output "secrets_policy_arn" {
  value       = aws_iam_policy.secrets.arn
  description = "The ARN of the IAM policy for accessing AWS Secrets Manager."
}

output "secrets_policy_name" {
  value       = aws_iam_policy.secrets.name
  description = "The name of the IAM policy for accessing AWS Secrets Manager."
}

output "ec2_role_name" {
  value       = aws_iam_role.ec2_role.name
  description = "The name of the IAM role for EC2 instances."
}

output "ec2_profile_name" {
  value       = aws_iam_instance_profile.ec2_instance_profile.name
  description = "The name of the IAM instance profile for EC2 instances."
}

output "secrets_policy_description" {
  value       = aws_iam_policy.secrets.description
  description = "The description of the IAM policy for accessing AWS Secrets Manager."
}

output "secrets_policy_actions" {
  value       = aws_iam_policy.secrets.policy
  description = "The actions allowed by the IAM policy for accessing AWS Secrets Manager."
}