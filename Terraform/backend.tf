# === Backend Infrastructure Management === #
# This file manages the S3 bucket and DynamoDB table used for Terraform state
# The GitHub Actions workflow creates these resources if they don't exist

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# S3 bucket for state storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = "devops-project-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# Enable versioning on state bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption on state bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
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
    ignore_changes = [tags]
  }
}
