resource "aws_ecs_cluster" "fastapi" {
  name = "fastapi-cluster"
}

resource "aws_ecs_task_definition" "fastapi" {
  family                   = "fastapi-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  region                   = data.aws_region.current.region
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions    = jsonencode([
    {
      name         = "fastapi"
      image        = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/receipt-extraction-gemma-4:latest"
      cpu          = 256
      memory       = 512
      essential    = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "fastapi" {
  name            = "fastapi-service"
  cluster         = aws_ecs_cluster.fastapi.id
  task_definition = aws_ecs_task_definition.fastapi.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.fastapi.arn
    container_name   = "fastapi"
    container_port   = 8000
  }

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_sg.id]
  }
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.fastapi.name}/${aws_ecs_service.fastapi.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "ecs-auto-scaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
  policy_type        = "PredictiveScaling"

  predictive_scaling_policy_configuration {
    metric_specification {
      target_value = 70

      predefined_metric_pair_specification {
        predefined_metric_type = "ECSServiceMemoryUtilization"
      }
    }
  }
}