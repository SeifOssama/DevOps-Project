
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  # Remote State Backend Configuration
  # Backend resources (S3 bucket & DynamoDB table) are created manually
  # Configuration values are passed at runtime via GitHub Actions secrets
  backend "s3" {
    # These values are configured via -backend-config flags during terraform init:
    #   -backend-config="bucket=${{ secrets.TF_BACKEND_BUCKET }}"
    #   -backend-config="dynamodb_table=${{ secrets.TF_BACKEND_DYNAMODB_TABLE }}"
    #   -backend-config="region=${{ secrets.TF_BACKEND_REGION }}"
    
    # Static values defined here:
    key     = "devops-project/terraform.tfstate"
    encrypt = true
  }
}


# ---------------------------------------------------------------------
# Setting the configurations of AWS provider
# ---------------------------------------------------------------------

provider "aws" {
  region = "us-east-1"
  # profile removed - GitHub Actions uses environment variables
  # For local development, set AWS_PROFILE environment variable
}

