# Archive du code Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/log_analyzer.py"
  output_path = "${path.module}/lambda/log_analyzer.zip"
}

data "aws_region" "current" {}

# IAM Role pour la Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-log-analyzer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-log-analyzer-role"
    Environment = var.environment
  }
}

# Policy : CloudWatch Logs (pour les logs de la Lambda elle-même)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy custom : SNS Publish uniquement (appel OpenAI via Internet, pas besoin de permission AWS)
resource "aws_iam_role_policy" "lambda_permissions" {
  name = "${var.project_name}-log-analyzer-permissions"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn
      }
    ]
  })
}

# Fonction Lambda
resource "aws_lambda_function" "log_analyzer" {
  function_name    = "${var.project_name}-log-analyzer"
  role             = aws_iam_role.lambda_role.arn
  handler          = "log_analyzer.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN  = var.sns_topic_arn
      OPENAI_API_KEY = var.openai_api_key
      OPENAI_MODEL   = var.openai_model
    }
  }

  tags = {
    Name        = "${var.project_name}-log-analyzer"
    Environment = var.environment
  }
}

# Permission : autoriser CloudWatch Logs à invoquer la Lambda
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowCloudWatchLogsInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_analyzer.function_name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = "${var.log_group_arn}:*"
}

# Subscription Filter : déclenche la Lambda sur pattern "ERROR"
resource "aws_cloudwatch_log_subscription_filter" "error_filter" {
  name            = "${var.project_name}-error-filter"
  log_group_name  = var.log_group_name
  filter_pattern  = "ERROR"
  destination_arn = aws_lambda_function.log_analyzer.arn

  depends_on = [aws_lambda_permission.allow_cloudwatch]
}

