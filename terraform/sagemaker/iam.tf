# SageMaker Execution Role
resource "aws_iam_role" "sagemaker" {
  name               = "sagemakerExecutionRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# SageMaker ECR Policy
resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.sagemaker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}