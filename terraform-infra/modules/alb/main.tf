# Application Load Balancer
locals {
  name = "${var.environment}-${var.project}-${var.tier}"
}

resource "aws_lb" "main" {
  name               = "${local.name}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = true
  drop_invalid_header_fields = true 
  idle_timeout               = 60

  tags = merge(var.tags, { Name = "${local.name}-alb" })
}

resource "aws_lb_target_group" "main" {
  name_prefix = "${substr(var.tier, 0, 5)}-" # max 6 characters
  port        = var.target_group_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  deregistration_delay = 30

  stickiness {
    type    = "lb_cookie"
    enabled = var.stickiness_enabled
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, { Name = "${local.name}-tg" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = var.enable_https ? "redirect" : "forward"
    target_group_arn = var.enable_https ? null : aws_lb_target_group.main.arn

    dynamic "redirect" {
      for_each = var.enable_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  tags = var.tags
}

resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = var.tags
}