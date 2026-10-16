#external load balancer security group
resource "aws_security_group" "alb" {
  name        = "alb_sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.alb_ingress_ports
    content {
      description = "Allow port ${ingress.value} from the internet"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.environment}-${var.project}-alb-sg" })
}


#internal load balancer security group
resource "aws_security_group" "internal_alb" {
  name        = "internal_alb_sg"
  description = "Security group for internal ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main_cidr.cidr_block]
    security_groups = [aws_security_group.frontend_instances.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main_cidr.cidr_block]
  }
    tags = {
        Name = "internal_alb_sg"
    }
}

resource "aws_security_group" "internal_alb-1" {
  name        = "internal_alb_sg"
  description = "Security group for internal ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main_cidr.cidr_block]
    security_groups = [aws_security_group.frontend_instances.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main_cidr.cidr_block]
  }
    tags = {
        Name = "internal_alb_sg-1"
    }
}

#security group for frontend instances
resource "aws_security_group" "frontend_instances" {
  name        = "frontend_instances_sg"
  description = "Security group for frontend instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic from VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
        Name = "frontend_instances_sg"
    }
}


#security group for backend instances
resource "aws_security_group" "backend_instances" {
  name        = "backend_instances_sg"
  description = "Security group for backend instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.internal_alb.id,aws_security_group.internal_alb-1.id]
  }

  ingress {
    description = "Allow HTTPS traffic from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
        Name = "backend_instances_sg"
    }
}

#security group for database instances
resource "aws_security_group" "database_instances" {
  name        = "database_instances_sg"
  description = "Security group for database instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MySQL traffic from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.backend_instances.id]
  }

  egress {
    description = "no outbound traffic allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }
    tags = {
        Name = "database_instances_sg"
    }
}