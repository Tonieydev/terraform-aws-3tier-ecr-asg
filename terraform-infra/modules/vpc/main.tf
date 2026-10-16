resource "aws_vpc" "main_vpc" {
 cidr_block = var.vpc_cidr
 enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main"
  } 
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  count = length(var.public_subnet_cidr)
  cidr_block = element(var.public_subnet_cidr, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
    tags = {
        Name = "public-subnet"
    }
}

resource "aws_subnet" "frontend_private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  count = length(var.frontend_private_subnet)
  cidr_block = element(var.frontend_private_subnet, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false
    tags = {
        Name = "Frontend-private-subnet"
    }
}

resource "aws_subnet" "backend_private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  count = length(var.backend_private_subnet)
  cidr_block = element(var.backend_private_subnet, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false
    tags = {
        Name = "Backend-private-subnet"
    }
}

resource "aws_subnet" "database_private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  count = length(var.database_private_subnet)
  cidr_block = element(var.database_private_subnet, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false
    tags = {
        Name = "Database-private-subnet"
    }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "main-igw"
  }
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  domain = "vpc"

  depends_on = [aws_internet_gateway.main_igw]
}

resource "aws_nat_gateway" "public_nat" {
  count         = length(aws_eip.nat)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
  depends_on    = [aws_internet_gateway.main_igw]

  tags = { Name = "nat-${count.index + 1}" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
    }
}

resource "aws_route_table_association" "public_rt_assoc" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "frontend_private_rt" {
  count  = length(aws_subnet.frontend_private_subnet)
  vpc_id = aws_vpc.main_vpc.id

  tags = { Name = "frontend-private-rt-${count.index + 1}" }
}

resource "aws_route" "frontend_nat" {
  count                  = var.enable_nat_gateway ? length(aws_subnet.frontend_private_subnet) : 0
  route_table_id         = aws_route_table.frontend_private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public_nat[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "frontend_private" {
  count          = length(aws_subnet.frontend_private_subnet)
  subnet_id      = aws_subnet.frontend_private_subnet[count.index].id
  route_table_id = aws_route_table.frontend_private_rt[count.index].id
}

resource "aws_route_table" "backend_private_rt" {
  count  = length(aws_subnet.backend_private_subnet)
  vpc_id = aws_vpc.main_vpc.id

  tags = { Name = "backend-private-rt-${count.index + 1}" }
}

resource "aws_route" "backend_nat" {
  count                  = var.enable_nat_gateway ? length(aws_subnet.backend_private_subnet) : 0
  route_table_id         = aws_route_table.backend_private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public_nat[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "backend_private" {
  count          = length(aws_subnet.backend_private_subnet)
  subnet_id      = aws_subnet.backend_private_subnet[count.index].id
  route_table_id = aws_route_table.backend_private_rt[count.index].id
}

resource "aws_route_table" "database_private_rt" {
  count  = length(aws_subnet.database_private_subnet)
  vpc_id = aws_vpc.main_vpc.id

  tags = { Name = "database-private-rt-${count.index + 1}" }
}

resource "aws_route_table_association" "database_private" {
  count          = length(aws_subnet.database_private_subnet)
  subnet_id      = aws_subnet.database_private_subnet[count.index].id
  route_table_id = aws_route_table.database_private_rt[count.index].id
}