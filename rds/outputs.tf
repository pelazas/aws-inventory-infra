# modules/rds/outputs.tf

output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}