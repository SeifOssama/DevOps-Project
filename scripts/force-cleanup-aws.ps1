# Complete AWS Cleanup Script
# This script will forcefully remove ALL resources created by the DevOps project

$ErrorActionPreference = "Continue"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║         AWS Complete Cleanup - DevOps Project            ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""

$REGION = "us-east-1"
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
$STATE_BUCKET = "devops-project-terraform-state-$ACCOUNT_ID"

Write-Host "AWS Account ID: $ACCOUNT_ID" -ForegroundColor Cyan
Write-Host "Region: $REGION" -ForegroundColor Cyan
Write-Host ""

# 1. Terminate All EC2 Instances with tag ManagedBy=Terraform
Write-Host "1️⃣ Terminating EC2 Instances..." -ForegroundColor Yellow
$instances = aws ec2 describe-instances `
    --region $REGION `
    --filters "Name=tag:ManagedBy,Values=Terraform" "Name=instance-state-name,Values=running,stopped,stopping" `
    --query 'Reservations[*].Instances[*].InstanceId' `
    --output text

if ($instances) {
    Write-Host "   Found instances: $instances" -ForegroundColor Gray
    aws ec2 terminate-instances --region $REGION --instance-ids $instances.Split()
    Write-Host "   ✅ Terminating instances..." -ForegroundColor Green
    Write-Host "   ⏳ Waiting for termination..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
} else {
    Write-Host "   ℹ️  No instances found" -ForegroundColor Gray
}

# 2. Delete EC2 Key Pairs
Write-Host ""
Write-Host "2️⃣ Deleting EC2 Key Pairs..." -ForegroundColor Yellow
aws ec2 delete-key-pair --region $REGION --key-name "deployer-key" 2>$null
if ($?) {
    Write-Host "   ✅ Deleted deployer-key" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  deployer-key not found" -ForegroundColor Gray
}

# 3. Delete IAM Resources
Write-Host ""
Write-Host "3️⃣ Deleting IAM Resources..." -ForegroundColor Yellow

# Detach instance profiles
Write-Host "   Detaching instance profiles..." -ForegroundColor Gray
aws iam remove-role-from-instance-profile --instance-profile-name "monitoring-node-profile" --role-name "monitoring-node-role" 2>$null
aws iam remove-role-from-instance-profile --instance-profile-name "webserver-profile" --role-name "webserver-role" 2>$null

# Delete instance profiles
aws iam delete-instance-profile --instance-profile-name "monitoring-node-profile" 2>$null
if ($?) { Write-Host "   ✅ Deleted monitoring-node-profile" -ForegroundColor Green }

aws iam delete-instance-profile --instance-profile-name "webserver-profile" 2>$null
if ($?) { Write-Host "   ✅ Deleted webserver-profile" -ForegroundColor Green }

# Detach managed policies from roles
Write-Host "   Detaching policies from roles..." -ForegroundColor Gray
aws iam detach-role-policy --role-name "monitoring-node-role" --policy-arn "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess" 2>$null
aws iam detach-role-policy --role-name "webserver-role" --policy-arn "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess" 2>$null

# Delete IAM roles
aws iam delete-role --role-name "monitoring-node-role" 2>$null
if ($?) { Write-Host "   ✅ Deleted monitoring-node-role" -ForegroundColor Green }

aws iam delete-role --role-name "webserver-role" 2>$null
if ($?) { Write-Host "   ✅ Deleted webserver-role" -ForegroundColor Green }

# 4. Delete Security Groups (retry with wait)
Write-Host ""
Write-Host "4️⃣ Deleting Security Groups..." -ForegroundColor Yellow
Write-Host "   ⏳ Waiting 30s for instances to fully terminate..." -ForegroundColor Gray
Start-Sleep -Seconds 30

$securityGroups = aws ec2 describe-security-groups `
    --region $REGION `
    --filters "Name=tag:ManagedBy,Values=Terraform" `
    --query 'SecurityGroups[*].[GroupId,GroupName]' `
    --output text

if ($securityGroups) {
    Write-Host "   Found security groups, attempting deletion..." -ForegroundColor Gray
    foreach ($sg in $securityGroups -split "`n") {
        if ($sg) {
            $sgId = ($sg -split "`t")[0]
            $sgName = ($sg -split "`t")[1]
            
            # Skip default security group
            if ($sgName -ne "default") {
                aws ec2 delete-security-group --region $REGION --group-id $sgId 2>$null
                if ($?) {
                    Write-Host "   ✅ Deleted $sgName ($sgId)" -ForegroundColor Green
                } else {
                    Write-Host "   ⚠️  Could not delete $sgName ($sgId) - may have dependencies" -ForegroundColor Yellow
                }
            }
        }
    }
} else {
    Write-Host "   ℹ️  No security groups found" -ForegroundColor Gray
}

# 5. Delete VPCs
Write-Host ""
Write-Host "5️⃣ Deleting VPCs..." -ForegroundColor Yellow

$vpcs = aws ec2 describe-vpcs `
    --region $REGION `
    --filters "Name=tag:ManagedBy,Values=Terraform" `
    --query 'Vpcs[*].VpcId' `
    --output text

if ($vpcs) {
    foreach ($vpcId in $vpcs.Split()) {
        if ($vpcId) {
            Write-Host "   Deleting VPC: $vpcId" -ForegroundColor Gray
            
            # Delete subnets
            $subnets = aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$vpcId" --query 'Subnets[*].SubnetId' --output text
            foreach ($subnet in $subnets.Split()) {
                if ($subnet) {
                    aws ec2 delete-subnet --region $REGION --subnet-id $subnet 2>$null
                }
            }
            
            # Delete internet gateways
            $igws = aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$vpcId" --query 'InternetGateways[*].InternetGatewayId' --output text
            foreach ($igw in $igws.Split()) {
                if ($igw) {
                    aws ec2 detach-internet-gateway --region $REGION --internet-gateway-id $igw --vpc-id $vpcId 2>$null
                    aws ec2 delete-internet-gateway --region $REGION --internet-gateway-id $igw 2>$null
                }
            }
            
            # Delete route tables (except main)
            $routeTables = aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$vpcId" --query 'RouteTables[?Associations[0].Main==`false`].RouteTableId' --output text
            foreach ($rt in $routeTables.Split()) {
                if ($rt) {
                    aws ec2 delete-route-table --region $REGION --route-table-id $rt 2>$null
                }
            }
            
            # Finally delete VPC
            aws ec2 delete-vpc --region $REGION --vpc-id $vpcId 2>$null
            if ($?) {
                Write-Host "   ✅ Deleted VPC $vpcId" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️  Could not delete VPC $vpcId" -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host "   ℹ️  No VPCs found with ManagedBy=Terraform tag" -ForegroundColor Gray
}

# 6. List remaining VPCs (to check limit)
Write-Host ""
Write-Host "6️⃣ Checking VPC Limit..." -ForegroundColor Yellow
$allVpcs = aws ec2 describe-vpcs --region $REGION --query 'Vpcs[*].[VpcId,IsDefault,Tags[?Key==`Name`].Value|[0]]' --output text
$vpcCount = ($allVpcs | Measure-Object -Line).Lines

Write-Host "   Total VPCs in region: $vpcCount" -ForegroundColor Cyan
if ($vpcCount -ge 5) {
    Write-Host "   ⚠️  WARNING: You have $vpcCount VPCs (limit is 5)" -ForegroundColor Red
    Write-Host "   You need to delete unused VPCs manually from AWS Console" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Current VPCs:" -ForegroundColor Yellow
    $allVpcs | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
}

# 7. Clear DynamoDB Locks
Write-Host ""
Write-Host "7️⃣ Clearing DynamoDB Locks..." -ForegroundColor Yellow
aws dynamodb delete-item `
    --table-name terraform-state-locks `
    --key "{`"LockID`": {`"S`": `"$STATE_BUCKET/devops-project/terraform.tfstate`"}}" `
    2>$null

if ($?) {
    Write-Host "   ✅ Cleared Terraform lock" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  No lock found" -ForegroundColor Gray
}

# 8. Optional: Delete DynamoDB Table
Write-Host ""
Write-Host "8️⃣ Deleting DynamoDB Table (terraform-state-locks)..." -ForegroundColor Yellow
Write-Host "   ⚠️  This will remove state locking capability" -ForegroundColor Yellow

$confirmation = Read-Host "   Delete DynamoDB table? (yes/no)"
if ($confirmation -eq "yes") {
    aws dynamodb delete-table --table-name terraform-state-locks 2>$null
    if ($?) {
        Write-Host "   ✅ Deleted terraform-state-locks table" -ForegroundColor Green
    }
} else {
    Write-Host "   ℹ️  Skipped DynamoDB table deletion" -ForegroundColor Gray
}

# 9. Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  Cleanup Complete                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Cleanup operations completed" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  IMPORTANT: If you saw warnings about VPC limit:" -ForegroundColor Yellow
Write-Host "   1. Go to AWS Console → VPC" -ForegroundColor Yellow
Write-Host "   2. Delete unused VPCs to free up space" -ForegroundColor Yellow
Write-Host "   3. You need less than 5 VPCs to deploy" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "   1. If VPC count < 5: Run Deploy workflow" -ForegroundColor Cyan
Write-Host "   2. If VPC count >= 5: Delete VPCs manually first" -ForegroundColor Cyan
