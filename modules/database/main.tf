# Subnet Group pour RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [var.private_subnet_id, var.private_subnet2_id]

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-rds"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.instance_class
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password

  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp2"

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]

  skip_final_snapshot     = true
  deletion_protection     = false
  publicly_accessible     = false
  multi_az                = false

  tags = {
    Name        = "${var.project_name}-rds"
    Environment = var.environment
  }
}