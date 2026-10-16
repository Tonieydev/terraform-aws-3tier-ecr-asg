resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-${var.project}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.project}-ec2-role"
  })
}

# Lets you connect with SSM Session Manager (replaces the bastion)
resource "aws_iam_role_policy_attachment" "Ssm_ManagedInstanceCore" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Lets the CloudWatch agent and Docker send logs and metrics
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Lets the instance pull images from ECR
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Lets the instance read only the secrets passed in
resource "aws_iam_policy" "secrets" {
  name        = "${var.environment}-${var.project}-secrets-read"
  description = "Read access to the application's Secrets Manager secrets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue"]
        Effect   = "Allow"
        Resource = var.secret_arns
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.project}-secrets-read"
  })
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.environment}-${var.project}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.project}-ec2-profile"
  })
}