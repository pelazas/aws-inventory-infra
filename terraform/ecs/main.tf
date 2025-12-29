resource "aws_ecs_cluster" "main" {
  name = "inventory-cluster"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role_inventory"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Let ECS task to read from secrets manager
resource "aws_iam_policy" "secrets_access" {
  name        = "ecs-secrets-access"
  description = "Allow ECS to read secrets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = var.db_password_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}
# Let task access S3
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


resource "aws_ecs_task_definition" "app" {
  family                   = "inventory-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn # Permite a la app (código) llamar a AWS S3

  container_definitions = jsonencode([{
    name      = "inventory-app"
    image     = var.app_image
    essential = true
    portMappings = [{ containerPort = 3000, hostPort = 3000 }]
    
    # A. Environment variables
    environment = [
      { name = "DB_HOST",        value = var.db_host },
      { name = "DB_NAME",        value = var.db_name },
      { name = "DB_USER",        value = var.db_user },
      { name = "S3_BUCKET_NAME", value = var.s3_bucket_name },
      { name = "AWS_REGION",     value = var.aws_region }
    ],

    # B. Secrets
    secrets = [
      { name = "DB_PASSWORD", valueFrom = var.db_password_arn }
    ],

    logConfiguration = {
        logDriver = "awslogs"
        options = {
            "awslogs-group"         = "/ecs/inventory-app"
            "awslogs-region"        = var.aws_region
            "awslogs-stream-prefix" = "ecs"
            "awslogs-create-group"  = "true"
        }
    }
  }])
}

# Servicio ECS
resource "aws_ecs_service" "main" {
  name            = "inventory-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  # Forzamos nuevo despliegue si cambia la imagen o la task def
  force_new_deployment = true

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = var.security_groups
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "inventory-app"
    container_port   = 3000
  }
}