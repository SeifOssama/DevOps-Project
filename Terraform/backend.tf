# === Backend Infrastructure Management === #
# This file manages the S3 bucket and DynamoDB table used for Terraform state
# These resources are imported if they already exist (created by GitHub Actions)

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Import existing S3 bucket for state storage
import {
  to = aws_s3_bucket.terraform_state
  id = "devops-project-terraform-state-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "devops-project-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Import existing versioning configuration
import {
  to = aws_s3_bucket_versioning.terraform_state
  id = "devops-project-terraform-state-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Import existing encryption configuration
import {
  to = aws_s3_bucket_server_side_encryption_configuration.terraform_state
  id = "devops-project-terraform-state-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Import existing public access block configuration
import {
  to = aws_s3_bucket_public_access_block.terraform_state
  id = "devops-project-terraform-state-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Import existing DynamoDB table for state locking
import {
  to = aws_dynamodb_table.terraform_locks
  id = "terraform-state-locks"
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}
