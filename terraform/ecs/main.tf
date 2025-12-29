resource "aws_ecs_cluster" "main" {
  name = "inventory-cluster"
}

# IAM Role  ECS to pull image from ECR and send logs
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

resource "aws_ecs_task_definition" "app" {
  family                   = "inventory-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "inventory-app"
    image     = var.app_image
    essential = true
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
    # HERE WE WILL ENVIRONMENT VARIABLES LATER
  }])
}

# The Service (Keeps the app running)
resource "aws_ecs_service" "main" {
  name            = "inventory-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

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