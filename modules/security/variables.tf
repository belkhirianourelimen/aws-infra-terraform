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

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_endpoint" {
  description = "RDS endpoint"
  type        = string
}