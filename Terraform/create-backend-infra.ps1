# Temporary script to create backend infrastructure only
# Run this first, then configure backend in provider.tf

Write-Host "🚀 Creating Terraform Backend Infrastructure" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

Set-Location $PSScriptRoot

# Get AWS Account ID
Write-Host "`n📋 Getting AWS Account ID..." -ForegroundColor Yellow
$accountId = aws sts get-caller-identity --query Account --output text
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get AWS Account ID" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Account ID: $accountId" -ForegroundColor Green

# Initialize
Write-Host "`n📋 Initializing Terraform..." -ForegroundColor Yellow
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Init failed" -ForegroundColor Red
    exit 1
}

# Create S3 bucket
Write-Host "`n📋 Creating S3 bucket..." -ForegroundColor Yellow
terraform apply -target aws_s3_bucket.terraform_state -auto-approve
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create S3 bucket" -ForegroundColor Red
    exit 1
}

# Create S3 versioning
Write-Host "`n📋 Enabling S3 versioning..." -ForegroundColor Yellow
terraform apply -target aws_s3_bucket_versioning.terraform_state -auto-approve
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to enable versioning" -ForegroundColor Red
    exit 1
}

# Create S3 encryption
Write-Host "`n📋 Enabling S3 encryption..." -ForegroundColor Yellow
terraform apply -target aws_s3_bucket_server_side_encryption_configuration.terraform_state -auto-approve
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to enable encryption" -ForegroundColor Red
    exit 1
}

# Block public access  
Write-Host "`n📋 Blocking S3 public access..." -ForegroundColor Yellow
terraform apply -target aws_s3_bucket_public_access_block.terraform_state -auto-approve
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to block public access" -ForegroundColor Red
    exit 1
}

# Create DynamoDB table
Write-Host "`n📋 Creating DynamoDB table..." -ForegroundColor Yellow
terraform apply -target aws_dynamodb_table.terraform_locks -auto-approve
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create DynamoDB table" -ForegroundColor Red
    exit 1
}

# Get outputs
Write-Host "`n✅ Backend infrastructure created!" -ForegroundColor Green
$bucketName = terraform output -raw s3_bucket_name
$tableName = terraform output -raw dynamodb_table_name

Write-Host "`nBackend Configuration:" -ForegroundColor Cyan
Write-Host "  S3 Bucket: $bucketName" -ForegroundColor White
Write-Host "  DynamoDB Table: $tableName" -ForegroundColor White

Write-Host "`n📝 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run: .\configure-backend.ps1" -ForegroundColor White
Write-Host "  2. This will update provider.tf and migrate state" -ForegroundColor White
