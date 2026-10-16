output "region" {
  value = var.region
}

output "application_url" {
  value = "http://${module.alb.alb_dns_name}"
}

output "backend_ecr_repository_url" {
  value = module.ecr.backend_repository_url
}

output "frontend_ecr_repository_url" {
  value = module.ecr.frontend_repository_url
}

output "helpful_commands" {
  value = <<-EOT
    Backend logs:   aws logs tail /aws/ec2/${local.name_prefix}/backend --follow --region ${var.region}
    Frontend logs:  aws logs tail /aws/ec2/${local.name_prefix}/frontend --follow --region ${var.region}
    Shell (SSM):    aws ssm start-session --target <instance-id> --region ${var.region}
  EOT
}