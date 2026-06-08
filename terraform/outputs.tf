# API Gateway endpoint URL used to invoke the health check API
output "api_url" {
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}/health"
  description = "Invoke URL for health endpoint"
}

# DynamoDB table name used by the Lambda function to store requests
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.requests.name
  description = "DynamoDB table name"
}

# Lambda function name for monitoring, testing, and troubleshooting
output "lambda_function_name" {
  value       = aws_lambda_function.health.function_name
  description = "Lambda function name"
}
