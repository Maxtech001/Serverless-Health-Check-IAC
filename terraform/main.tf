# Terraform version and AWS provider requirements
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "stateless-health-check-api1"
    key     = "health-check/terraform.tfstate"
    region  = "eu-north-1"
    encrypt = true
  }

}
# Configure AWS provider and deployment region
provider "aws" {
  region = var.aws_region
}

# Local naming convention used across resources
locals {
  prefix = "${var.environment}-${var.project_name}"
}

# DynamoDB table used to store incoming health check requests
resource "aws_dynamodb_table" "requests" {
  name         = "${var.environment}-requests-db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption { enabled = true }

  tags = {
    Name        = "${var.environment}-requests-db"
    Environment = var.environment
  }
}

# IAM role assumed by the Lambda function
resource "aws_iam_role" "lambda_role" {
  name               = "${local.prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = { Environment = var.environment }
}

# Trust policy allowing Lambda service to assume the IAM role
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Least-privilege IAM policy for Lambda logging and DynamoDB access
resource "aws_iam_policy" "lambda_policy" {
  name        = "${local.prefix}-lambda-policy"
  description = "Least-privilege policy for health-check lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${local.prefix}-health-check-function:*"
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DescribeTable"
        ],
        Resource = aws_dynamodb_table.requests.arn
      }
    ]
  })
}

# Attach IAM policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function that processes health check requests
resource "aws_lambda_function" "health" {
  function_name = "${local.prefix}-health-check-function"
  filename      = var.lambda_zip_path
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      DDB_TABLE_NAME = aws_dynamodb_table.requests.name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway REST API exposing the health endpoint
resource "aws_api_gateway_rest_api" "api" {
  name        = "${local.prefix}-api"
  description = "REST API for health check"
}

# Create the /health API resource path
resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "health"
}

# Configure POST method for the /health endpoint
resource "aws_api_gateway_method" "health_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.health.id
  http_method   = "POST"
  authorization = "NONE"
}

# Connect API Gateway to Lambda using proxy integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.health.id
  http_method             = aws_api_gateway_method.health_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.health.invoke_arn
}

# Allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/POST/health"
}

# Deploy API Gateway configuration changes
resource "aws_api_gateway_deployment" "api" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeploy = sha1(jsonencode(aws_lambda_function.health.*.last_modified))
  }
}

# Create environment-specific API stage (staging/prod)
resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = var.environment
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id

}

# Configure API Gateway throttling to reduce abuse and DDoS impact
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 100
  }
}

