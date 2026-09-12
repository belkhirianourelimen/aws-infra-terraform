# SNS Topic pour les alertes
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = {
    Name        = "${var.project_name}-alerts"
    Environment = var.environment
  }
}

# SNS Subscription — Email
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.project_name}/application"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-logs"
    Environment = var.environment
  }
}

# Alarme CPU EC2
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "${var.project_name}-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU utilization is too high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.ec2_instance_id
  }

  tags = {
    Name        = "${var.project_name}-ec2-cpu-alarm"
    Environment = var.environment
  }
}

# Alarme CPU RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization is too high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  tags = {
    Name        = "${var.project_name}-rds-cpu-alarm"
    Environment = var.environment
  }
}

# Alarme stockage RDS
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2000000000
  alarm_description   = "RDS free storage is too low"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  tags = {
    Name        = "${var.project_name}-rds-storage-alarm"
    Environment = var.environment
  }
}

# Alarme : la Lambda IA elle-même échoue
resource "aws_cloudwatch_metric_alarm" "lambda_ai_errors" {
  alarm_name          = "${var.project_name}-lambda-ai-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "La fonction Lambda de diagnostic IA (wellnesshub-log-analyzer) a rencontré une erreur d'exécution"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name        = "${var.project_name}-lambda-ai-errors-alarm"
    Environment = var.environment
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Ligne 1 — Infrastructure de base
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "EC2 CPU Utilization"
          region  = "us-east-1"
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.ec2_instance_id]
          ]
          annotations = {
            horizontal = [
              { label = "Seuil alarme", value = 80 }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "RDS CPU Utilization"
          region  = "us-east-1"
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_identifier]
          ]
          annotations = {
            horizontal = [
              { label = "Seuil alarme", value = 80 }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "RDS Free Storage"
          region  = "us-east-1"
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_identifier]
          ]
          annotations = {
            horizontal = []
          }
        }
      },

      # Ligne 2 — Titre section IA
      {
        type   = "text"
        x      = 0
        y      = 6
        width  = 24
        height = 1
        properties = {
          markdown = "## 🤖 Monitoring IA — Feature 2 (CloudWatch + Lambda + OpenAI)"
        }
      },

      # Ligne 3 — Lambda IA
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 8
        height = 6
        properties = {
          title   = "Lambda IA — Invocations"
          region  = "us-east-1"
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name]
          ]
          annotations = {
            horizontal = []
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 7
        width  = 8
        height = 6
        properties = {
          title   = "Lambda IA — Erreurs"
          region  = "us-east-1"
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", var.lambda_function_name]
          ]
          annotations = {
            horizontal = [
              { label = "Seuil critique", value = 1 }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 7
        width  = 8
        height = 6
        properties = {
          title   = "Lambda IA — Durée d'exécution (ms)"
          region  = "us-east-1"
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", var.lambda_function_name]
          ]
          annotations = {
            horizontal = []
          }
        }
      },

      # Ligne 4 — Logs Insights : dernières erreurs
      {
        type   = "log"
        x      = 0
        y      = 13
        width  = 24
        height = 8
        properties = {
          title   = "🔍 Dernières erreurs détectées (logs applicatifs)"
          region  = "us-east-1"
          query   = "SOURCE '/${var.project_name}/application' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          view    = "table"
        }
      },

      # Ligne 5 — Titre section ALB
      {
        type   = "text"
        x      = 0
        y      = 21
        width  = 24
        height = 1
        properties = {
          markdown = "## 🌐 Trafic Application (ALB)"
        }
      },

      # Ligne 6 — ALB
      {
        type   = "metric"
        x      = 0
        y      = 22
        width  = 12
        height = 6
        properties = {
          title   = "ALB — Requêtes par minute"
          region  = "us-east-1"
          period  = 60
          stat    = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]
          ]
          annotations = {
            horizontal = []
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 22
        width  = 12
        height = 6
        properties = {
          title   = "ALB — Hôtes sains / non sains"
          region  = "us-east-1"
          period  = 60
          stat    = "Average"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", var.target_group_arn_suffix, "LoadBalancer", var.alb_arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", var.target_group_arn_suffix, "LoadBalancer", var.alb_arn_suffix]
          ]
          annotations = {
            horizontal = []
          }
        }
      }
    ]
  })
}