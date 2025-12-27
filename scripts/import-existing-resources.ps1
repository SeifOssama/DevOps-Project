# Import Existing Resources into Terraform State
# This script imports resources that already exist in AWS into Terraform's state

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        Importing Existing Resources into Terraform        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$REGION = "us-east-1"
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)

Write-Host "AWS Account ID: $ACCOUNT_ID" -ForegroundColor Yellow
Write-Host ""

# Change to Terraform directory
Set-Location -Path "Terraform"

# ============================================
# Step 1: Initialize Terraform
# ============================================
Write-Host "Step 1: Initializing Terraform..." -ForegroundColor Cyan

terraform init `
  -backend-config="bucket=devops-project-terraform-state-$ACCOUNT_ID" `
  -backend-config="dynamodb_table=terraform-state-locks" `
  -backend-config="region=$REGION" `
  -reconfigure

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform init failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Terraform initialized" -ForegroundColor Green
Write-Host ""

# ============================================
# Step 2: Import EC2 Key Pair
# ============================================
Write-Host "Step 2: Importing EC2 Key Pair..." -ForegroundColor Cyan

$keyPairExists = aws ec2 describe-key-pairs --key-names deployer-key --region $REGION 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   Found key pair: deployer-key" -ForegroundColor White
    
    terraform import aws_key_pair.deployer deployer-key
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Key pair imported successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Key pair import failed (may already be in state)" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  Key pair 'deployer-key' not found in AWS" -ForegroundColor Gray
}

Write-Host ""

# ============================================
# Step 3: Import IAM Role
# ============================================
Write-Host "Step 3: Importing IAM Role..." -ForegroundColor Cyan

$roleExists = aws iam get-role --role-name monitoring-node-role 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   Found IAM role: monitoring-node-role" -ForegroundColor White
    
    terraform import module.controlnode.aws_iam_role.control_node_role monitoring-node-role
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ IAM role imported successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  IAM role import failed (may already be in state)" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  IAM role 'monitoring-node-role' not found in AWS" -ForegroundColor Gray
}

Write-Host ""

# ============================================
# Step 4: Import IAM Role Policy Attachment
# ============================================
Write-Host "Step 4: Importing IAM Role Policy Attachments..." -ForegroundColor Cyan

$policyArn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

$attachmentExists = aws iam list-attached-role-policies --role-name monitoring-node-role --query "AttachedPolicies[?PolicyArn=='$policyArn']" --output text 2>$null
if ($attachmentExists) {
    Write-Host "   Found policy attachment: AmazonSSMManagedInstanceCore" -ForegroundColor White
    
    terraform import module.controlnode.aws_iam_role_policy_attachment.ssm_policy "monitoring-node-role/$policyArn"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Policy attachment imported successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Policy attachment import failed (may already be in state)" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  Policy attachment not found" -ForegroundColor Gray
}

Write-Host ""

# ============================================
# Step 5: Check for other existing resources
# ============================================
Write-Host "Step 5: Checking for other existing resources..." -ForegroundColor Cyan

# Check for VPC
Write-Host "   Checking for VPC..." -ForegroundColor White
$vpcs = aws ec2 describe-vpcs --filters "Name=tag:ManagedBy,Values=Terraform" --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output text
if ($vpcs) {
    Write-Host "   ⚠️  Found existing VPCs:" -ForegroundColor Yellow
    Write-Host "$vpcs" -ForegroundColor Gray
    Write-Host "   Note: These will need manual import if you want to preserve them" -ForegroundColor Yellow
}

# Check for EC2 instances
Write-Host "   Checking for EC2 instances..." -ForegroundColor White
$instances = aws ec2 describe-instances --filters "Name=tag:ManagedBy,Values=Terraform" "Name=instance-state-name,Values=running,stopped,stopping,pending" --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' --output text
if ($instances) {
    Write-Host "   ⚠️  Found existing EC2 instances:" -ForegroundColor Yellow
    Write-Host "$instances" -ForegroundColor Gray
    Write-Host "   Note: These will need manual import if you want to preserve them" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# Step 6: Verify State
# ============================================
Write-Host "Step 6: Verifying Terraform State..." -ForegroundColor Cyan

Write-Host "   Resources now in state:" -ForegroundColor White
terraform state list

Write-Host ""

# ============================================
# Summary
# ============================================
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  ✅ Import Complete!                       ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Resources imported into Terraform state:" -ForegroundColor Yellow
Write-Host "  • EC2 Key Pair: deployer-key" -ForegroundColor White
Write-Host "  • IAM Role: monitoring-node-role" -ForegroundColor White
Write-Host "  • IAM Policy Attachment (if exists)" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run: terraform plan" -ForegroundColor White
Write-Host "  2. Review the plan - should show minimal or no changes" -ForegroundColor White
Write-Host "  3. If plan looks good, re-run GitHub Actions workflow" -ForegroundColor White
Write-Host ""
Write-Host "Note: If you see other existing resources above, you may need to" -ForegroundColor Cyan
Write-Host "      import them manually or delete them first." -ForegroundColor Cyan

# Return to root directory
Set-Location -Path ".."
