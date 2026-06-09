# Serverless Health Check API (AWS, Terraform & GitHub Actions)

## Overview

This project implements a serverless health check API on AWS using Infrastructure as Code (Terraform) and automated deployment through GitHub Actions.
The solution exposes a `/health` endpoint through API Gateway, invokes an AWS Lambda function, logs requests to CloudWatch, stores request data in DynamoDB, and supports deployment to separate staging and production environments.

The project was built as part of a DevOps engineering assessment with a focus on:

* Infrastructure as Code
* CI/CD automation
* Security best practices
* Multi-environment deployments
* Least-privilege IAM permissions
* Serverless AWS architecture

---

## Architecture

                GitHub Actions
                       │
                       ▼
                 Terraform Apply
                       │
 ┌──────────────────────────────────────┐
 │               AWS                    │
 └──────────────────────────────────────┘
                       │
                       ▼
                 API Gateway
                       │
                       ▼
                    Lambda
                       │
         ┌─────────────┴─────────────┐
         ▼                           ▼
   CloudWatch Logs             DynamoDB

```

### Request Flow

1. Client sends a request to `/health`
2. API Gateway receives the request
3. API Gateway invokes Lambda
4. Lambda validates request payload
5. Lambda logs request details to CloudWatch
6. Lambda writes request data to DynamoDB
7. Lambda returns a JSON success response

---

## AWS Resources

### API Gateway

Provides the public `/health` endpoint.

Features:

* HTTP endpoint
* Request throttling enabled
* Lambda integration
* Environment-specific naming


### Lambda Function

Responsible for:

* Receiving API Gateway requests
* Validating incoming JSON payload
* Logging request information
* Writing request data to DynamoDB
* Returning API responses

Note:

staging-health-check-function
prod-health-check-function

---

### DynamoDB

Stores request information.

Note:
staging-requests-db
prod-requests-db

Schema:

| Attribute | Type   | Purpose                   |
| --------- | ------ | ------------------------- |
| id        | String | Unique request identifier |
| payload   | String | Request payload           |
| timestamp | String | Request timestamp         |

Security:

* Server-Side Encryption (SSE) enabled
* Access restricted to Lambda IAM role

---

### IAM Roles

#### Lambda Execution Role

Permissions are restricted to:

* CloudWatch logging
* DynamoDB PutItem
* Required Lambda execution permissions

Least privilege principles are followed.

#### Deployment Role

Used by GitHub Actions during deployment.

Permissions are scoped only to resources required by Terraform to manage:

* Lambda
* API Gateway
* DynamoDB
* IAM
* CloudWatch
---

## Project Structure

serverless-health-check/
│
├── lambda/
│   ├── index.js
│   ├── package.json
│   └── package-lock.json
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│
├── envs/
│   ├── staging.tfvars
│   └── prod.tfvars
│
├── .github/
│   └── workflows/
│       └── ci-cd.yml
│
└── README.md
```

---

## Multi-Environment Design

The infrastructure supports two isolated environments:

* staging
* prod

Environment-specific values are managed through Terraform variable files.

Note:

bash
terraform apply -var-file="../envs/staging.tfvars"
``
bash
terraform apply -var-file="../envs/prod.tfvars"

---

## Lambda Function Behaviour

### Successful Request

Request:

```json
{
  "payload": "health-check-test"
}
```

Lambda actions:

1. Validates payload exists
2. Generates UUID
3. Logs request to CloudWatch
4. Writes item to DynamoDB
5. Returns success response

Response:

```json
{
  "status": "healthy",
  "message": "Request processed and saved."
}
```

---

### Invalid Request

Request:

```json
{}
```

Response:

```json
{
  "error": "payload is required"
}
```

Status:

400 Bad Request

---

## Security Controls

### Infrastructure Security

Implemented controls:

* Terraform-managed infrastructure
* DynamoDB Server-Side Encryption
* Dedicated IAM roles
* Least-privilege permissions
* No wildcard permissions where avoidable

---

### API Protection

API Gateway throttling is configured to reduce abuse and limit excessive requests.

Note:

* Rate limiting
* Burst limits

This helps mitigate basic denial-of-service scenarios.

---

### Input Validation

The Lambda function validates that:

```json
{
  "payload": "..."
}
```

is present before processing requests.

Requests missing the payload field are rejected.

---

### Dependency Security Scanning

The CI pipeline performs dependency scanning for Lambda packages before deployment.

Note:

* npm audit
* vulnerability checks

Deployments fail when critical issues are detected.

---

### Infrastructure Security Scanning

Terraform code is scanned using:

tfsec

```

Security findings must pass before deployment proceeds.

---

## CI/CD Pipeline

GitHub Actions automates validation and deployment.

Workflow stages:

### CI Stage

1. Checkout repository
2. Install Lambda dependencies
3. Package Lambda artifact
4. Run Terraform formatting checks
5. Run Terraform validation
6. Run dependency scanning
7. Run tfsec security scan

Pipeline stops if any step fails.

---

### Deployment Stage

1. Authenticate to AWS
2. Execute Terraform plan
3. Execute Terraform apply
4. Deploy infrastructure updates

Deployments are environment-specific.

---

## Required GitHub Secrets

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION

---

## Deploying Staging

### Automatic Deployment

Push changes to the configured deployment branch (master).

GitHub Actions will:

1. Validate code
2. Run security scans
3. Deploy infrastructure

---

### Manual Deployment

bash
cd terraform

terraform init
terraform fmt
terraform validate
terraform plan var-file="../envs/staging.tfvars"
terraform apply var-file="../envs/staging.tfvars"
```

---

## Obtaining API Endpoint

After deployment:

bash
terraform output -raw api_url
``

---

## Testing the Endpoint

### Successful Request

bash
curl -X POST "$(terraform output -raw api_url)" \
-H "Content-Type: application/json" \
-d '{"payload":"health-check-test"}'

```

Expected Response:

```json
{
  "status": "healthy",
  "message": "Request processed and saved."
}
```

---

### Invalid Request

```bash
curl -X POST "$(terraform output -raw api_url)" \
-H "Content-Type: application/json" \
-d '{}'
```

Expected Response:

```json
{
  "error": "payload is required"
}
```

---

## Author

Jude Ifeanyi Eze

DevOps Engineer
