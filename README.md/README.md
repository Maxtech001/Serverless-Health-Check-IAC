# Serverless Health Check API (AWS + Terraform + CI/CD)

OVERVIEW
This project deploys a serverless /health API using AWS Lambda, API Gateway, and DynamoDB.
Infrastructure is managed using Terraform and deployed via GitHub Actions CI/CD.

---

ARCHITECTURE
Client → API Gateway → Lambda → DynamoDB

---

PROJECT STRUCTURE

lambda/     → Node.js Lambda function
terraform/  → Infrastructure as Code (AWS resources)
envs/       → Environment configs (staging/prod)
.github/    → CI/CD pipeline

## serverless-health-check/

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
├── .github/workflows/
│   └── ci-cd.yml
│
└── README.md
---

PREREQUISITES
You need:

- AWS account + IAM user (programmatic access)
- Terraform >= 1.5
- Node.js >= 18
- GitHub repository with secrets configured

---

GITHUB SECRETS
Required for CI/CD deployment:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

---

DEPLOYMENT (GITHUB ACTIONS)

1. Push code to main branch → CI runs automatically
2. Or manually trigger workflow → choose staging/prod
3. Terraform deploys full infrastructure

---

LOCAL DEPLOYMENT (OPTIONAL)

Step 1: Build Lambda package
cd lambda
npm install
zip -r ../health-check-lambda.zip .
cd ..

Step 2: Deploy with Terraform
cd terraform
terraform init
terraform plan -var-file="../envs/staging.tfvars"
terraform apply -var-file="../envs/staging.tfvars" -auto-approve

---

TESTING API

After deployment, get API URL:
terraform output api_url

Test with curl:
curl -X POST "$(terraform output -raw api_url)" \
  -H "Content-Type: application/json" \
  -d '{"payload":"ping"}'

---

EXPECTED RESPONSE
{
  "status": "healthy",
  "message": "Request processed and saved."
}

---

LAMBDA LOGIC

- Receives API Gateway event
- Parses JSON body
- Validates "payload"
- Stores request in DynamoDB
- Returns success response

---

DYNAMODB SCHEMA
id         → String (Primary Key)
payload    → String
timestamp  → ISO string

---

SECURITY FEATURES

- IAM least privilege role
- DynamoDB server-side encryption (SSE)
- Input validation in Lambda
- tfsec security scanning in CI/CD

---

CI/CD PIPELINE

CI stage:

- Install dependencies
- Package Lambda
- Terraform fmt + validate
- tfsec scan

Deploy stage:

- Uses GitHub Secrets for AWS auth
- Runs Terraform plan & apply
- Supports staging & prod environments

---

ENVIRONMENTS
staging → envs/staging.tfvars
prod    → envs/prod.tfvars

---

NOTES

- Do NOT commit node_modules
- Lambda ZIP is generated during CI/CD
- Ensure AWS permissions include Lambda, API Gateway, DynamoDB, IAM

---

CLEANUP
cd terraform
terraform destroy -var-file="../envs/staging.tfvars"

---

## Author

Jude Ifeanyi Eze (Devops Engineer)
