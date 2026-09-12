variable "aws_region" {
  description = "AWS region used for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "wellnesshub"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API Key for AI diagnostics"
  type        = string
  sensitive   = true
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarms and SNS notifications"
  type        = string
  default     = "n.belkhiria@wellnesshub.com.tn"
}