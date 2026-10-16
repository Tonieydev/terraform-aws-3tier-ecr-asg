output "vpc_id" {
    description = "The ID of the VPC"
  value = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
    description = "The IDs of the public subnets"
  value = aws_subnet.public_subnet[*].id
}

output "frontend_private_subnet_ids" {
    description = "The IDs of the frontend private subnets"
  value = aws_subnet.frontend_private_subnet[*].id
}

output "backend_private_subnet_ids" {
  description = "The IDs of the backend private subnets"
  value = aws_subnet.backend_private_subnet[*].id
}

output "database_private_subnet_ids" {
  description = "The IDs of the database private subnets"
  value = aws_subnet.database_private_subnet[*].id
}

output "nat_gateway_ids" {
    description = "The IDs of the NAT gateways"
  value = aws_nat_gateway.public_nat[*].id
}

output "internet_gateway_id" {
    description = "The ID of the Internet Gateway"
  value = aws_internet_gateway.main_igw.id
}

output "vpc_cidr_block" {
    description = "The CIDR block of the VPC"
  value = aws_vpc.main_vpc.cidr_block
}