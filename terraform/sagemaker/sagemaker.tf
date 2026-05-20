data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get AWS Account ID and AWS Region from above data
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
}

# Create SageMaker Model with Gemma 4 on vLLM
resource "aws_sagemaker_model" "model" {
  name                = "gemma-4-receipt-extraction-vllm"
  execution_role_arn  = aws_iam_role.sagemaker.arn
  primary_container {
    image             = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/vllm-gemma-4:0.19.1-sagemaker"
    environment       = {
      "SM_VLLM_MODEL" = "google/gemma-4-E4B-it"
    }
  }
}

# Create SageMaker Endpoint Configuration
resource "aws_sagemaker_endpoint_configuration" "endpointConfig" {
  name  = aws_sagemaker_model.model.name
  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.model.name
    initial_instance_count = 1
    instance_type          = "ml.g6.2xlarge"
  }
}

# Create SageMaker Endpoint
resource "aws_sagemaker_endpoint" "endpoint" {
  name                 = aws_sagemaker_model.model.name
  endpoint_config_name = aws_sagemaker_endpoint_configuration.endpointConfig.name
}