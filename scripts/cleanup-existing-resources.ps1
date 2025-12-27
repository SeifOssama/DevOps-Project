# Cleanup Script - Delete Existing Resources
# Run this to clean up resources that already exist from previous runs

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║          Cleaning Up Existing AWS Resources               ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""

$REGION = "us-east-1"

# ============================================
# Step 1: Delete EC2 Key Pair
# ============================================
Write-Host "Step 1: Deleting EC2 Key Pair..." -ForegroundColor Cyan

try {
    aws ec2 delete-key-pair --key-name deployer-key --region $REGION 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Key pair 'deployer-key' deleted" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  Key pair 'deployer-key' not found (already deleted or doesn't exist)" -ForegroundColor Gray
    }
} catch {
    Write-Host "ℹ️  Could not delete key pair (may not exist)" -ForegroundColor Gray
}

Write-Host ""

# ============================================
# Step 2: Delete IAM Role
# ============================================
Write-Host "Step 2: Detaching IAM Role Policies..." -ForegroundColor Cyan

$ROLE_NAME = "monitoring-node-role"

# Get attached policies
try {
    $attachedPolicies = aws iam list-attached-role-policies --role-name $ROLE_NAME --query 'AttachedPolicies[].PolicyArn' --output text 2>$null
    
    if ($attachedPolicies) {
        $policyArns = $attachedPolicies -split "`t"
        foreach ($policyArn in $policyArns) {
            Write-Host "   Detaching policy: $policyArn" -ForegroundColor White
            aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $policyArn
        }
        Write-Host "✅ All policies detached from role" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  No attached policies found" -ForegroundColor Gray
    }
} catch {
    Write-Host "ℹ️  Could not list policies (role may not exist)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Step 3: Deleting IAM Role..." -ForegroundColor Cyan

try {
    aws iam delete-role --role-name $ROLE_NAME 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ IAM role '$ROLE_NAME' deleted" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  IAM role '$ROLE_NAME' not found (already deleted or doesn't exist)" -ForegroundColor Gray
    }
} catch {
    Write-Host "ℹ️  Could not delete IAM role (may not exist)" -ForegroundColor Gray
}

Write-Host ""

# ============================================
# Summary
# ============================================
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  ✅ Cleanup Complete!                      ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Resources cleaned up:" -ForegroundColor Yellow
Write-Host "  • EC2 Key Pair: deployer-key" -ForegroundColor White
Write-Host "  • IAM Role: monitoring-node-role" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Go to GitHub Actions" -ForegroundColor White
Write-Host "  2. Re-run 'Deploy Infrastructure & Services' workflow" -ForegroundColor White
Write-Host "  3. Terraform will create these resources fresh" -ForegroundColor White
Write-Host ""
Write-Host "Note: S3 bucket and DynamoDB table are PRESERVED (not deleted)" -ForegroundColor Cyan
