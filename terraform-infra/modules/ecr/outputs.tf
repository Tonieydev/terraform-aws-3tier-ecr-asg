output "repository_urls" {
  description = "Map of component to repository URL."
  value       = { for k, r in aws_ecr_repository.main_ecr : k => r.repository_url }
}

output "repository_arns" {
  description = "Map of component to repository ARN. Use to scope IAM pull permissions."
  value       = { for k, r in aws_ecr_repository.main_ecr : k => r.arn }
}

output "repository_names" {
  description = "Map of component to repository name."
  value       = { for k, r in aws_ecr_repository.main_ecr : k => r.name }
}

output "backend_repository_url" {
  description = "Backend repository URL."
  value       = aws_ecr_repository.main_ecr["backend"].repository_url
}

output "frontend_repository_url" {
  description = "Frontend repository URL."
  value       = aws_ecr_repository.main_ecr["frontend"].repository_url
}

output "registry" {
  description = "Registry host (<account>.dkr.ecr.<region>.amazonaws.com), used for docker login."
  value       = split("/", aws_ecr_repository.main_ecr["backend"].repository_url)[0]
}
