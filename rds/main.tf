# generate a random password for the RDS instance
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# save password in secrets manager
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.env}/inventory-api/db-password-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  
  # for dev environments
  recovery_window_in_days = 0 
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# Security Group
resource "aws_security_group" "rds_sg" {
  name        = "${var.env}-rds-sg"
  description = "Security Group for RDS"
  vpc_id      = var.vpc_id

  # Inbound: Only from app
  # CHANGE according to the SG of the application
  
  tags = {
    Name = "${var.env}-rds-sg"
  }
}

# Subnet Group for RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.env}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.env}-db-subnet-group"
  }
}

# RDS
resource "aws_db_instance" "main" {
  identifier        = "${var.env}-inventory-db"
  engine            = "postgres"
  engine_version    = "14" 
  instance_class    = var.db_instance_class
  allocated_storage = 20
  
  db_name  = "inventory_db"
  username = "dbadmin"
  password = random_password.db_password.result # we use the generated password
  
  # Network and Security
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true  # For dev. In PROD set to false.
  
  tags = {
    Name = "${var.env}-inventory-db"
  }
}