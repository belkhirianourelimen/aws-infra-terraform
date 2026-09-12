variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "services" {
  description = "List of microservices to create ECR repositories for"
  type        = list(string)
  default     = ["eureka", "gateway", "expertms", "front"]
}