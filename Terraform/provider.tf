
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
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

