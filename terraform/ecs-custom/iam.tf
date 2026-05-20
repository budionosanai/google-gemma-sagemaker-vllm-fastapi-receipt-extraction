data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get AWS Account ID and AWS Region from above data
locals {
  account_id = data.aws_caller_identity.current.account_id
  region = data.aws_region.current.region
}

# ECS Express Infrastructure Role
resource "aws_iam_role" "infrastructure" {
  name = "ecsExpressInfrastructure"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ECS Express Infrastructure Policy
resource "aws_iam_role_policy_attachment" "infrastructure" {
  role       = aws_iam_role.infrastructure.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices"
}

# ECS Express Execution Role
resource "aws_iam_role" "execution" {
  name = "ecsExpressExecution"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ECS Express Execution Policy
resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Express Task Role
resource "aws_iam_role" "task" {
  name = "ecsExpressTask"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ECS Express Task Policy to SageMaker Endpoint
resource "aws_iam_role_policy" "sagemaker" {
  name = "ecsExpressSagemaker"
  role = aws_iam_role.task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
            "sagemaker:InvokeEndpoint"
        ]
        Resource = "arn:aws:sagemaker:${local.region}:${local.account_id}:endpoint/*"
      }
    ]
  })
}