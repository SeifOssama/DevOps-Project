
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  # Remote State Backend Configuration
  backend "s3" {
    bucket         = "devops-project-terraform-state-724772082485"
    key            = "devops-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
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

