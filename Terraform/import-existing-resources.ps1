# ========================================================
# Import Existing AWS Resources into Terraform State
# ========================================================
# This script imports AWS resources that already exist in AWS
# but aren't tracked in Terraform's state file.
#
# Run this when you get "resource already exists" errors.

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Importing Existing AWS Resources" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Get AWS Account ID
Write-Host "🔍 Getting AWS Account ID..." -ForegroundColor Yellow
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get AWS Account ID. Check your AWS credentials." -ForegroundColor Red
    exit 1
}

Write-Host "✅ AWS Account ID: $ACCOUNT_ID" -ForegroundColor Green
Write-Host ""

# Resource names
$BUCKET_NAME = "devops-project-terraform-state-$ACCOUNT_ID"
$TABLE_NAME = "terraform-state-locks"
$KEY_NAME = "deployer-key"

Write-Host "📦 Resources to import:" -ForegroundColor Cyan
Write-Host "   - S3 Bucket: $BUCKET_NAME"
Write-Host "   - DynamoDB Table: $TABLE_NAME"
Write-Host "   - EC2 Key Pair: $KEY_NAME"
Write-Host ""

# Initialize Terraform (if not already done)
Write-Host "🔧 Initializing Terraform..." -ForegroundColor Yellow
terraform init -migrate-state -input=false

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform init failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Terraform initialized" -ForegroundColor Green
Write-Host ""

# Import S3 Bucket
Write-Host "📦 [1/3] Importing S3 Bucket..." -ForegroundColor Yellow
$bucketExists = (aws s3 ls "s3://$BUCKET_NAME" 2>$null)
if ($LASTEXITCODE -eq 0) {
    terraform import aws_s3_bucket.terraform_state $BUCKET_NAME
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ S3 Bucket imported successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  S3 Bucket import failed (may already be in state)" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  S3 Bucket doesn't exist in AWS - skipping" -ForegroundColor Gray
}
Write-Host ""

# Import DynamoDB Table
Write-Host "📊 [2/3] Importing DynamoDB Table..." -ForegroundColor Yellow
$tableExists = (aws dynamodb describe-table --table-name $TABLE_NAME 2>$null)
if ($LASTEXITCODE -eq 0) {
    terraform import aws_dynamodb_table.terraform_locks $TABLE_NAME
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ DynamoDB Table imported successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  DynamoDB Table import failed (may already be in state)" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  DynamoDB Table doesn't exist in AWS - skipping" -ForegroundColor Gray
}
Write-Host ""

# Import EC2 Key Pair
Write-Host "🔑 [3/3] Importing EC2 Key Pair..." -ForegroundColor Yellow
$keyExists = (aws ec2 describe-key-pairs --key-names $KEY_NAME 2>$null)
if ($LASTEXITCODE -eq 0) {
    terraform import aws_key_pair.deployer $KEY_NAME
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ EC2 Key Pair imported successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  EC2 Key Pair import failed (may already be in state)" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  EC2 Key Pair doesn't exist in AWS - skipping" -ForegroundColor Gray
}
Write-Host ""

# Verify state
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Verification" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "📋 Checking Terraform state..." -ForegroundColor Yellow
$stateResources = (terraform state list)

if ($stateResources) {
    Write-Host "✅ Resources now in state:" -ForegroundColor Green
    $stateResources | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
} else {
    Write-Host "⚠️  No resources in state yet" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "✅ Import Complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run: terraform plan -var='ssh_public_key=YOUR_SSH_PUBLIC_KEY'" -ForegroundColor White
Write-Host "2. Verify the plan shows no errors" -ForegroundColor White
Write-Host "3. Run: terraform apply -var='ssh_public_key=YOUR_SSH_PUBLIC_KEY'" -ForegroundColor White
