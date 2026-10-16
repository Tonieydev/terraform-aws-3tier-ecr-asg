output "endpoint" {
  value = aws_db_instance.main.address
}

output "master_secret_arn" {
  value = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "db_address" {
  value = aws_db_instance.main.db_address
}

output "db_port" {
  value = aws_db_instance.main.port
}

# db_secret_arn = module.rds.master_secret_arn
  #db_host       = module.rds.db_address
  #db_port       = module.rds.db_port