resource "aws_lb" "main" {
  name               = "inventory-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.public_subnets

  tags = {
    Name = "inventory-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "inventory-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Necessary for Fargate

  health_check {
    path                = "/health" # at server.js in app/
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}