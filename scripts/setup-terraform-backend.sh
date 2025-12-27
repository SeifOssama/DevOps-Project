#!/bin/bash
# Script to manually create Terraform backend infrastructure
# Run this ONCE before using Terraform with remote state

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Terraform Backend Infrastructure Setup (Manual)       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
REGION="us-east-1"
BUCKET_NAME_PREFIX="devops-project-terraform-state"
DYNAMODB_TABLE="terraform-state-locks"

# Get AWS Account ID
echo "📋 Getting AWS Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "   AWS Account: $ACCOUNT_ID"
echo ""

# Construct unique bucket name
BUCKET_NAME="$BUCKET_NAME_PREFIX-$ACCOUNT_ID"

echo "📝 Backend Configuration:"
echo "   S3 Bucket:       $BUCKET_NAME"
echo "   DynamoDB Table:  $DYNAMODB_TABLE"
echo "   Region:          $REGION"
echo ""

# ============================================
# Create S3 Bucket
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Creating S3 Bucket for Terraform State..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
    echo "✅ S3 bucket already exists: $BUCKET_NAME"
else
    echo "📦 Creating S3 bucket: $BUCKET_NAME"
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region $REGION
    
    echo "✅ S3 bucket created"
fi

echo ""
echo "⚙️  Configuring S3 bucket..."

# Enable versioning
echo "   📌 Enabling versioning..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable encryption
echo "   🔐 Enabling server-side encryption..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }]
    }'

# Block public access
echo "   🚫 Blocking public access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Add lifecycle policy for cost optimization
echo "   ♻️  Configuring lifecycle policy..."
aws s3api put-bucket-lifecycle-configuration \
    --bucket "$BUCKET_NAME" \
    --lifecycle-configuration '{
      "Rules": [{
        "Id": "DeleteOldVersions",
        "Status": "Enabled",
        "NoncurrentVersionExpiration": {
          "NoncurrentDays": 90
        }
      }]
    }'

# Add tags
echo "   🏷️  Adding tags..."
aws s3api put-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --tagging 'TagSet=[
      {Key=Name,Value="Terraform State Bucket"},
      {Key=Environment,Value="Production"},
      {Key=ManagedBy,Value="Manual"},
      {Key=Purpose,Value="Terraform Backend"}
    ]'

echo "✅ S3 bucket configured successfully"
echo ""

# ============================================
# Create DynamoDB Table
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Creating DynamoDB Table for State Locking..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region $REGION 2>/dev/null; then
    echo "✅ DynamoDB table already exists: $DYNAMODB_TABLE"
else
    echo "📊 Creating DynamoDB table: $DYNAMODB_TABLE"
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region $REGION \
        --tags \
          Key=Name,Value="Terraform State Lock Table" \
          Key=Environment,Value="Production" \
          Key=ManagedBy,Value="Manual" \
          Key=Purpose,Value="Terraform State Locking"
    
    echo "   ⏳ Waiting for table to become active..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region $REGION
    
    echo "✅ DynamoDB table created successfully"
fi

echo ""

# ============================================
# Verify Setup
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Verifying Backend Infrastructure..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check S3 bucket
echo "📦 S3 Bucket Status:"
aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" | jq -r '"   Versioning: " + .Status'
aws s3api get-bucket-encryption --bucket "$BUCKET_NAME" | jq -r '"   Encryption: " + .ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm'
aws s3api get-public-access-block --bucket "$BUCKET_NAME" | jq -r '"   Public Access Blocked: " + (.PublicAccessBlockConfiguration.BlockPublicAcls|tostring)'

echo ""
echo "📊 DynamoDB Table Status:"
TABLE_STATUS=$(aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region $REGION --query 'Table.TableStatus' --output text)
BILLING_MODE=$(aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region $REGION --query 'Table.BillingModeSummary.BillingMode' --output text)
echo "   Status: $TABLE_STATUS"
echo "   Billing: $BILLING_MODE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Backend Infrastructure Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 NEXT STEPS:"
echo ""
echo "1. Add these GitHub Secrets to your repository:"
echo "   Go to: Settings > Secrets and variables > Actions > New repository secret"
echo ""
echo "   Secret Name: TF_BACKEND_BUCKET"
echo "   Secret Value: $BUCKET_NAME"
echo ""
echo "   Secret Name: TF_BACKEND_DYNAMODB_TABLE"
echo "   Secret Value: $DYNAMODB_TABLE"
echo ""
echo "   Secret Name: TF_BACKEND_REGION"
echo "   Secret Value: $REGION"
echo ""
echo "2. Your provider.tf should have this backend configuration:"
echo ""
echo "   terraform {"
echo "     backend \"s3\" {"
echo "       # Configured via -backend-config flags in GitHub Actions"
echo "       # bucket         = configured at runtime"
echo "       # dynamodb_table = configured at runtime"
echo "       key            = \"devops-project/terraform.tfstate\""
echo "       region         = \"us-east-1\""
echo "       encrypt        = true"
echo "     }"
echo "   }"
echo ""
echo "3. In GitHub Actions, initialize Terraform with:"
echo ""
echo "   terraform init \\"
echo "     -backend-config=\"bucket=\${{ secrets.TF_BACKEND_BUCKET }}\" \\"
echo "     -backend-config=\"dynamodb_table=\${{ secrets.TF_BACKEND_DYNAMODB_TABLE }}\" \\"
echo "     -backend-config=\"region=\${{ secrets.TF_BACKEND_REGION }}\""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💰 COST ESTIMATE (AWS Free Tier):"
echo "   • S3 Bucket: ~\$0.00/month (first 5GB free, state files are tiny)"
echo "   • DynamoDB: ~\$0.00/month (first 25GB & 200M requests free)"
echo "   • Expected monthly cost: \$0.00 (within free tier)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
