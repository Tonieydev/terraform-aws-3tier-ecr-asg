locals {
  repositories = toset(var.repositories)

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    Module      = "ecr"
  })

  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.untagged_expiry_days} day(s)"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_expiry_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the ${var.max_image_count} most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_repository" "main_ecr" {
  for_each = local.repositories

  name                 = "${var.environment}-${var.project}-${each.key}"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Name      = "${var.environment}-${var.project}-${each.key}"
    Component = each.key
  })
}

resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  for_each = aws_ecr_repository.main_ecr

  repository = each.value.name
  policy     = local.lifecycle_policy
}
