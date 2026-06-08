# AWS region where all infrastructure resources will be deployed
variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-north-1"
}

# Deployment environment used for resource naming and separation
variable "environment" {
  type        = string
  description = "Environment (staging or prod)"
}

# Base project name used as part of resource names
variable "project_name" {
  type        = string
  description = "Project name"
  default     = "health-check"
}

# Location of the packaged Lambda ZIP file used during deployment
variable "lambda_zip_path" {
  type        = string
  description = "Path to Lambda deployment package"
  default     = "../health-check-lambda.zip"
}
