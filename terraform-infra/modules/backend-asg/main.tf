data "aws_ami" "backend_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_launch_template" "backend" {
  name_prefix   = "backend"
  image_id      = data.aws_ami.backend_ami.id
  instance_type = var.instance_type

    iam_instance_profile {
        name = var.iam_instance_profile
    }

    vpc_security_group_ids = var.security_group_ids

   user_data = base64encode(templatefile("${path.module}/scripts/backend_user_data.sh", {
  docker_image  = var.docker_image
  ecr_registry  = var.ecr_registry
  db_secret_arn = var.db_secret_arn
  db_host       = var.db_host
  db_port       = var.db_port
  db_name       = var.db_name
  region        = var.region
  environment   = var.environment
  project       = var.project
}))

    block_device_mappings {
        device_name = "/dev/xvda"

        ebs {
            volume_size = 20
            volume_type = "gp3"
            encrypted   = true
            delete_on_termination = true
        }
        
    }

    metadata_options {
        http_tokens               = "required"
        http_endpoint             = "enabled"
        http_put_response_hop_limit = 1
        instance_metadata_tags       = "enabled"
    }

    monitoring {
        enabled = true
    }

    tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.environment}-${var.project}-backend"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name = "${var.environment}-${var.project}-backend-volume"
      }
    )
  }
}


resource "aws_autoscaling_group" "backend_asg" {
  name = "backend"
  desired_capacity   = var.desired_size
  max_size           = var.max_size
  min_size           = var.min_size
  vpc_zone_identifier = var.subnet_ids
  health_check_type = "ELB"
  health_check_grace_period = 300
  target_group_arns         = var.target_group_arns
  

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  tag {
    key                 = "Name"
    value               = "${var.environment}-${var.project}-frontend"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# Target Tracking Scaling Policy - CPU
resource "aws_autoscaling_policy" "backend_cpu" {
  name                   = "${var.environment}-${var.project}-backend-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.backend_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# CloudWatch Alarm - High CPU
resource "aws_cloudwatch_metric_alarm" "backend_high_cpu" {
  alarm_name          = "${var.environment}-${var.project}-backend-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors backend EC2 CPU utilization"
  alarm_actions       = var.alarm_actions

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.backend_asg.name
  }

  tags = var.tags
}
