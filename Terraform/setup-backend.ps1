#!/usr/bin/env pwsh
# Setup script for Terraform Remote State Backend

Write-Host "🚀 Setting up Terraform Remote State Backend" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Set-Location $PSScriptRoot

# Step 1: Get AWS Account ID
Write-Host "`n📋 Step 1: Getting AWS Account ID..." -ForegroundColor Yellow
$accountId = aws sts get-caller-identity --query Account --output text
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get AWS Account ID. Make sure AWS CLI is configured." -ForegroundColor Red
    exit 1
}
Write-Host "✅ AWS Account ID: $accountId" -ForegroundColor Green

# Step 2: Initialize Terraform (without backend)
Write-Host "`n📋 Step 2: Initializing Terraform..." -ForegroundColor Yellow
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform init failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Terraform initialized" -ForegroundColor Green

# Step 3: Create backend infrastructure
Write-Host "`n📋 Step 3: Creating S3 bucket and DynamoDB table..." -ForegroundColor Yellow
Write-Host "This will create:" -ForegroundColor Cyan
Write-Host "  - S3 Bucket: devops-project-terraform-state-$accountId" -ForegroundColor Cyan
Write-Host "  - DynamoDB Table: terraform-state-locks" -ForegroundColor Cyan

terraform apply -target=aws_s3_bucket.terraform_state `
                -target=aws_s3_bucket_versioning.terraform_state `
                -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state `
                -target=aws_s3_bucket_public_access_block.terraform_state `
                -target=aws_dynamodb_table.terraform_locks `
                -target=data.aws_caller_identity.current `
                -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create backend infrastructure" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Backend infrastructure created" -ForegroundColor Green

# Step 4: Get outputs
Write-Host "`n📋 Step 4: Getting backend configuration..." -ForegroundColor Yellow
$bucketName = terraform output -raw s3_bucket_name
$tableName = terraform output -raw dynamodb_table_name

Write-Host "✅ Backend infrastructure ready!" -ForegroundColor Green
Write-Host "`nBackend Configuration:" -ForegroundColor Cyan
Write-Host "  S3 Bucket: $bucketName" -ForegroundColor White
Write-Host "  DynamoDB Table: $tableName" -ForegroundColor White

# Step 5: Update provider.tf
Write-Host "`n📋 Step 5: Updating provider.tf with backend configuration..." -ForegroundColor Yellow

$providerContent = Get-Content "provider.tf" -Raw
if ($providerContent -match 'backend\s+"s3"') {
    Write-Host "⚠️  Backend already configured in provider.tf" -ForegroundColor Yellow
} else {
    # Backup original
    Copy-Item "provider.tf" "provider.tf.backup"
    Write-Host "✅ Backed up provider.tf to provider.tf.backup" -ForegroundColor Green
    
    # Read current content and find where to insert backend
    $content = Get-Content "provider.tf" -Raw
    
    # Insert backend configuration after required_providers block
    $backendConfig = @"

  # Remote State Backend Configuration
  backend "s3" {
    bucket         = "$bucketName"
    key            = "devops-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "$tableName"
    encrypt        = true
  }
"@
    
    # Find the position to insert (after the closing brace of required_providers)
    $pattern = '(required_providers\s*{[^}]*}\s*)'
    $newContent = $content -replace $pattern, "`$1$backendConfig"
    
    $newContent | Set-Content "provider.tf"
    Write-Host "✅ Updated provider.tf with backend configuration" -ForegroundColor Green
}

# Step 6: Migrate state to S3
Write-Host "`n📋 Step 6: Migrating state to S3 backend..." -ForegroundColor Yellow
Write-Host "⚠️  This will migrate your local state to S3" -ForegroundColor Yellow

# Reinitialize with backend
terraform init -migrate-state -force-copy

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ State successfully migrated to S3!" -ForegroundColor Green
    Write-Host "`n🎉 Setup Complete!" -ForegroundColor Cyan
    Write-Host "Your Terraform state is now stored in S3 and will work seamlessly with GitHub Actions." -ForegroundColor Green
    
    # Cleanup local state
    if (Test-Path "terraform.tfstate.backup") {
        Write-Host "`n📦 Local state backup exists at: terraform.tfstate.backup" -ForegroundColor Cyan
        Write-Host "You can safely delete it after verifying remote state works." -ForegroundColor Cyan
    }
    
    # Test the setup
    Write-Host "`n📋 Testing remote state..." -ForegroundColor Yellow
    terraform state list
    
    Write-Host "`n✅ Remote state backend is working!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Commit and push changes to GitHub" -ForegroundColor White
    Write-Host "  2. GitHub Actions will now use the remote state" -ForegroundColor White
    Write-Host "  3. No more 'resource already exists' errors!" -ForegroundColor White
} else {
    Write-Host "❌ State migration failed" -ForegroundColor Red
    Write-Host "Your local state is unchanged. Fix the issue and try again." -ForegroundColor Yellow
    exit 1
}
