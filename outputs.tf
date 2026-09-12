output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = module.compute.ec2_public_ip
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.registry.repository_urls
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.database.rds_endpoint
}