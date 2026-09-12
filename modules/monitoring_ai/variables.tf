variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "log_group_name" {
  description = "CloudWatch log group to monitor for errors"
  type        = string
}

variable "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN to publish diagnostics to"
  type        = string
}

variable "openai_api_key" {
  description = "OpenAI API Key for AI log diagnostics"
  type        = string
  sensitive   = true
}

variable "openai_model" {
  description = "OpenAI model to use for diagnostics"
  type        = string
  default     = "gpt-4o-mini"
}