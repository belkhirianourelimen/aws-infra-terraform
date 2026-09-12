variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet1_id" {
  type = string
}

variable "public_subnet2_id" {
  type = string
}

variable "ec2_security_group_id" {
  type = string
}

variable "ec2_instance_id" {
  type = string
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN"
}