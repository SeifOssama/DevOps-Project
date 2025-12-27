# ============================================
# Terraform Backend Setup - Step by Step Guide
# ============================================
# Run these commands one at a time in PowerShell

# STEP 1: Get your AWS Account ID
# ============================================
Write-Host "STEP 1: Getting AWS Account ID..." -ForegroundColor Cyan
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
Write-Host "Your AWS Account ID: $ACCOUNT_ID" -ForegroundColor Green

# STEP 2: Set variables
# ============================================
$BUCKET_NAME = "devops-project-terraform-state-$ACCOUNT_ID"
$DYNAMODB_TABLE = "terraform-state-locks"
$REGION = "us-east-1"

Write-Host "`nConfiguration:" -ForegroundColor Cyan
Write-Host "  Bucket: $BUCKET_NAME" -ForegroundColor White
Write-Host "  Table: $DYNAMODB_TABLE" -ForegroundColor White
Write-Host "  Region: $REGION" -ForegroundColor White

# STEP 3: Create S3 Bucket
# ============================================
Write-Host "`nSTEP 3: Creating S3 Bucket..." -ForegroundColor Cyan
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
Write-Host "✅ Bucket created" -ForegroundColor Green

# STEP 4: Enable Versioning
# ============================================
Write-Host "`nSTEP 4: Enabling versioning..." -ForegroundColor Cyan
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
Write-Host "✅ Versioning enabled" -ForegroundColor Green

# STEP 5: Enable Encryption
# ============================================
Write-Host "`nSTEP 5: Enabling encryption..." -ForegroundColor Cyan
aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"},\"BucketKeyEnabled\":true}]}'
Write-Host "✅ Encryption enabled" -ForegroundColor Green

# STEP 6: Block Public Access
# ============================================
Write-Host "`nSTEP 6: Blocking public access..." -ForegroundColor Cyan
aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
Write-Host "✅ Public access blocked" -ForegroundColor Green

# STEP 7: Create DynamoDB Table
# ============================================
Write-Host "`nSTEP 7: Creating DynamoDB table..." -ForegroundColor Cyan
aws dynamodb create-table --table-name $DYNAMODB_TABLE --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region $REGION
Write-Host "✅ Table created" -ForegroundColor Green

# STEP 8: Wait for table to be active
# ============================================
Write-Host "`nSTEP 8: Waiting for table to become active..." -ForegroundColor Cyan
aws dynamodb wait table-exists --table-name $DYNAMODB_TABLE --region $REGION
Write-Host "✅ Table is active" -ForegroundColor Green

# STEP 9: Display GitHub Secrets
# ============================================
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              ✅ BACKEND SETUP COMPLETE!                   ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📝 Add these GitHub Secrets:" -ForegroundColor Yellow
Write-Host "`nSecret 1:" -ForegroundColor Cyan
Write-Host "  Name:  TF_BACKEND_BUCKET" -ForegroundColor White
Write-Host "  Value: $BUCKET_NAME" -ForegroundColor White

Write-Host "`nSecret 2:" -ForegroundColor Cyan
Write-Host "  Name:  TF_BACKEND_DYNAMODB_TABLE" -ForegroundColor White
Write-Host "  Value: $DYNAMODB_TABLE" -ForegroundColor White

Write-Host "`nSecret 3:" -ForegroundColor Cyan
Write-Host "  Name:  TF_BACKEND_REGION" -ForegroundColor White
Write-Host "  Value: $REGION" -ForegroundColor White

Write-Host "`n💡 To add secrets:" -ForegroundColor Yellow
Write-Host "  1. Go to your GitHub repository" -ForegroundColor Gray
Write-Host "  2. Click Settings > Secrets and variables > Actions" -ForegroundColor Gray
Write-Host "  3. Click 'New repository secret'" -ForegroundColor Gray
Write-Host "  4. Add each secret above" -ForegroundColor Gray
