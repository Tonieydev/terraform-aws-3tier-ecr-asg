locals {
  name = "${var.environment}-${var.project}"
}

# ---------------------------------------------------------------- External ALB
# Internet → ALB on the listener ports (80 now; 443 once HTTPS exists)

resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "External ALB: public HTTP"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.alb_ingress_ports
    content {
      description = "Port ${ingress.value} from the internet"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-alb-sg" })
}

# ---------------------------------------------------------------- Frontend instances
# External ALB → frontend on 3000

resource "aws_security_group" "frontend_instances" {
  name        = "${local.name}-frontend-sg"
  description = "Frontend instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App traffic from the external ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound (internal ALB, ECR, CloudWatch via NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-frontend-sg" })
}

# ---------------------------------------------------------------- Internal ALB
# Frontend → internal ALB on 80

resource "aws_security_group" "internal_alb" {
  name        = "${local.name}-internal-alb-sg"
  description = "Internal ALB: frontend to backend"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from frontend instances"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_instances.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-internal-alb-sg" })
}

# ---------------------------------------------------------------- Backend instances
# Internal ALB → backend on 8080

resource "aws_security_group" "backend_instances" {
  name        = "${local.name}-backend-sg"
  description = "Backend instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App traffic from the internal ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
  }

  egress {
    description = "All outbound (RDS, ECR, Secrets Manager, CloudWatch via NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-backend-sg" })
}

# ---------------------------------------------------------------- Database
# Backend → RDS PostgreSQL on 5432. No egress: responses are allowed automatically.

resource "aws_security_group" "database_instances" {
  name        = "${local.name}-rds-sg"
  description = "RDS PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from backend instances"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_instances.id]
  }

  tags = merge(var.tags, { Name = "${local.name}-rds-sg" })
}