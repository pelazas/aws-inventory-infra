variable "vpc_id" {}

# 1. ALB SG: Allow HTTP traffic from anywhere
resource "aws_security_group" "alb" {
  name   = "inventory-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. ECS SG: Allow traffic ONLY from the ALB
resource "aws_security_group" "ecs" {
  name   = "inventory-ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # IMPORTANT
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. RDS SG: Allow traffic ONLY from ECS
resource "aws_security_group" "rds" {
  name   = "inventory-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432 # Postgres
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
}

output "alb_sg_id" { value = aws_security_group.alb.id }
output "ecs_sg_id" { value = aws_security_group.ecs.id }
output "rds_sg_id" { value = aws_security_group.rds.id }