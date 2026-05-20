# Create ECS Cluster
resource "aws_ecs_cluster" "fastapiecs" {
  name = "fastapiecs"
}

# Create ECS Express Service that linked with receipt extraction ECR image
resource "aws_ecs_express_gateway_service" "fastapi" {
  cluster                 = aws_ecs_cluster.fastapiecs.name
  execution_role_arn      = aws_iam_role.execution.arn
  infrastructure_role_arn = aws_iam_role.infrastructure.arn
  task_role_arn           = aws_iam_role.task.arn
  health_check_path       = "/health"
  cpu                     = "256"
  memory                  = "512"
  region                  = data.aws_region.current.region

  primary_container {
    image          = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/receipt-extraction-gemma-4:latest"
    container_port = 8000
  }

  network_configuration {
    subnets         = aws_subnet.public[*].id
    security_groups = [aws_security_group.alb_sg.id]
  }

  scaling_target {
    auto_scaling_metric       = "AVERAGE_CPU"
    auto_scaling_target_value = 70
    min_task_count            = 1
    max_task_count            = 3
  }
}