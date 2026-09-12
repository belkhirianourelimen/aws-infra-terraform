variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "ec2_instance_id" {
  description = "ID of the EC2 instance"
  type        = string
}

variable "rds_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
  default     = "n.belkhiria@wellnesshub.com.tn"
}

variable "lambda_function_name" {
  description = "Name of the AI diagnostic Lambda function"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB (for CloudWatch metrics)"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group (for CloudWatch metrics)"
  type        = string
}