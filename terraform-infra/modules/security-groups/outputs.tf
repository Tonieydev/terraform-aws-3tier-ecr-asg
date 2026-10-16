output "internal_alb_sg_id" {
  value       = aws_security_group.internal_alb.id
  description = "The ID of the internal ALB security group"
}

output "frontend_instances_sg_id" {
  value       = aws_security_group.frontend_instances.id
  description = "The ID of the frontend instances security group"
}

output "backend_instances_sg_id" {
  value       = aws_security_group.backend_instances.id
  description = "The ID of the backend instances security group"
}

output "database_instances_sg_id" {
  value       = aws_security_group.database_instances.id
  description = "The ID of the database instances security group"
}

output "alb_sg_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the ALB security group"
}
