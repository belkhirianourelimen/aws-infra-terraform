# IAM Role pour EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Environment = var.environment
  }
}

# Policy EC2 → ECR
resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Policy EC2 → CloudWatch
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Policy EC2 → SSM
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# SSM Parameter Store — DB Password
resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.project_name}/db/password"
  description = "Database password"
  type        = "SecureString"
  value       = var.db_password

  tags = {
    Name        = "${var.project_name}-db-password"
    Environment = var.environment
  }
}

# SSM Parameter Store — DB Username
resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.project_name}/db/username"
  description = "Database username"
  type        = "String"
  value       = var.db_username

  tags = {
    Name        = "${var.project_name}-db-username"
    Environment = var.environment
  }
}

# SSM Parameter Store — DB Endpoint
resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/${var.project_name}/db/endpoint"
  description = "Database endpoint"
  type        = "String"
  value       = var.db_endpoint

  tags = {
    Name        = "${var.project_name}-db-endpoint"
    Environment = var.environment
  }
}