module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  environment  = var.environment
}

module "compute" {
  source                = "./modules/compute"
  project_name          = var.project_name
  environment           = var.environment
  public_subnet_id      = module.network.public_subnet_id
  ec2_security_group_id = module.network.ec2_security_group_id
  key_name              = "${var.project_name}-key"
  iam_instance_profile_name = module.security.ec2_instance_profile_name
}

module "database" {
  source                = "./modules/database"
  project_name          = var.project_name
  environment           = var.environment
  private_subnet_id     = module.network.private_subnet_id
  private_subnet2_id = module.network.private_subnet2_id
  rds_security_group_id = module.network.rds_security_group_id
  db_password           = var.db_password
}

module "registry" {
  source       = "./modules/registry"
  project_name = var.project_name
  environment  = var.environment
}

module "security" {
  source          = "./modules/security"
  project_name    = var.project_name
  environment     = var.environment
  ec2_instance_id = module.compute.ec2_instance_id
  db_password     = var.db_password
  db_username     = "wellnessadmin"
  db_endpoint     = module.database.rds_endpoint
}

data "aws_acm_certificate" "main" {
  domain   = "wellnesshub.dev"
  statuses = ["ISSUED"]
}

module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.network.vpc_id
  public_subnet1_id     = module.network.public_subnet_id
  public_subnet2_id     = module.network.public_subnet2_id
  ec2_security_group_id = module.network.ec2_security_group_id
  ec2_instance_id       = module.compute.ec2_instance_id
  certificate_arn       = data.aws_acm_certificate.main.arn
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name              = var.project_name
  environment                = var.environment
  ec2_instance_id            = module.compute.ec2_instance_id
  rds_identifier              = module.database.rds_identifier
  alarm_email                 = var.alarm_email
  lambda_function_name        = "${var.project_name}-log-analyzer"  # nom prévisible, pas besoin d'attendre la création
  alb_arn_suffix               = module.alb.alb_arn_suffix
  target_group_arn_suffix      = module.alb.target_group_arn_suffix
}

module "monitoring_ai" {
  source = "./modules/monitoring_ai"

  project_name     = var.project_name
  environment      = var.environment
  log_group_name   = module.monitoring.log_group_name
  log_group_arn    = module.monitoring.log_group_arn
  sns_topic_arn    = module.monitoring.sns_topic_arn
  openai_api_key   = var.openai_api_key
  openai_model     = "gpt-4o-mini"
}