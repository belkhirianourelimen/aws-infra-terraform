output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "db_password_ssm_path" {
  description = "SSM path for database password"
  value       = aws_ssm_parameter.db_password.name
}

output "db_username_ssm_path" {
  description = "SSM path for database username"
  value       = aws_ssm_parameter.db_username.name
}

output "db_endpoint_ssm_path" {
  description = "SSM path for database endpoint"
  value       = aws_ssm_parameter.db_endpoint.name
}