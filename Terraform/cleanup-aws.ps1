# Complete AWS Resource Cleanup Script
# WARNING: This will delete ALL resources managed by your Terraform configuration
# Use with caution!

param(
    [Parameter(Mandatory=$false)]
    [switch]$KeepBackend = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf = $false
)

$region = "us-east-1"
$vpcId = "vpc-0d248715dea692390"
$s3Bucket = "devops-project-terraform-state-724772082485"
$dynamoTable = "terraform-state-locks"
$keyPairName = "deployer-key"

Write-Host "=== AWS Resource Cleanup Script ===" -ForegroundColor Cyan
Write-Host "Region: $region" -ForegroundColor Yellow
Write-Host "Keep Backend: $KeepBackend" -ForegroundColor Yellow
Write-Host "WhatIf Mode: $WhatIf" -ForegroundColor Yellow
Write-Host ""

# Function to run AWS commands
function Invoke-AWSCommand {
    param([string]$Command, [string]$Description)
    
    Write-Host ">>> $Description" -ForegroundColor Green
    if ($WhatIf) {
        Write-Host "    [WHATIF] $Command" -ForegroundColor DarkGray
    } else {
        Write-Host "    Executing: $Command" -ForegroundColor DarkGray
        Invoke-Expression $Command
    }
}

# Step 1: Terminate EC2 Instances
Write-Host "`n=== Step 1: Terminating EC2 Instances ===" -ForegroundColor Cyan
$instances = aws ec2 describe-instances --region $region --filters "Name=tag:Project,Values=DevOps" "Name=instance-state-name,Values=running,stopped,stopping" --query "Reservations[].Instances[].InstanceId" --output text

if ($instances -and $instances.Trim() -ne "") {
    Write-Host "Found instances: $instances" -ForegroundColor Yellow
    Invoke-AWSCommand -Command "aws ec2 terminate-instances --region $region --instance-ids $instances" -Description "Terminating instances"
    
    if (-not $WhatIf) {
        Write-Host "Waiting for instances to terminate..." -ForegroundColor Yellow
        aws ec2 wait instance-terminated --region $region --instance-ids $instances
        Write-Host "All instances terminated." -ForegroundColor Green
    }
} else {
    Write-Host "No EC2 instances found." -ForegroundColor Gray
}

# Step 2: Delete Network Interfaces
Write-Host "`n=== Step 2: Deleting Network Interfaces ===" -ForegroundColor Cyan
Start-Sleep -Seconds 10  # Wait for instance termination to release ENIs

$enis = aws ec2 describe-network-interfaces --region $region --filters "Name=vpc-id,Values=$vpcId" --query "NetworkInterfaces[?Status=='available'].NetworkInterfaceId" --output text

if ($enis -and $enis.Trim() -ne "") {
    foreach ($eni in $enis.Split()) {
        if ($eni.Trim() -ne "") {
            Invoke-AWSCommand -Command "aws ec2 delete-network-interface --region $region --network-interface-id $eni" -Description "Deleting ENI $eni"
        }
    }
} else {
    Write-Host "No available network interfaces found." -ForegroundColor Gray
}

# Step 3: Delete Security Groups
Write-Host "`n=== Step 3: Deleting Security Groups ===" -ForegroundColor Cyan
Start-Sleep -Seconds 5  # Wait for ENI deletion

$securityGroups = aws ec2 describe-security-groups --region $region --filters "Name=vpc-id,Values=$vpcId" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text

if ($securityGroups -and $securityGroups.Trim() -ne "") {
    foreach ($sg in $securityGroups.Split()) {
        if ($sg.Trim() -ne "") {
            Invoke-AWSCommand -Command "aws ec2 delete-security-group --region $region --group-id $sg" -Description "Deleting security group $sg"
        }
    }
} else {
    Write-Host "No custom security groups found." -ForegroundColor Gray
}

# Step 4: Delete Subnets
Write-Host "`n=== Step 4: Deleting Subnets ===" -ForegroundColor Cyan
$subnets = aws ec2 describe-subnets --region $region --filters "Name=vpc-id,Values=$vpcId" --query "Subnets[].SubnetId" --output text

if ($subnets -and $subnets.Trim() -ne "") {
    foreach ($subnet in $subnets.Split()) {
        if ($subnet.Trim() -ne "") {
            Invoke-AWSCommand -Command "aws ec2 delete-subnet --region $region --subnet-id $subnet" -Description "Deleting subnet $subnet"
        }
    }
} else {
    Write-Host "No subnets found." -ForegroundColor Gray
}

# Step 5: Delete Route Tables
Write-Host "`n=== Step 5: Deleting Route Tables ===" -ForegroundColor Cyan
$routeTables = aws ec2 describe-route-tables --region $region --filters "Name=vpc-id,Values=$vpcId" --query "RouteTables[?Associations[0].Main==``false``].RouteTableId" --output text

if ($routeTables -and $routeTables.Trim() -ne "") {
    foreach ($rt in $routeTables.Split()) {
        if ($rt.Trim() -ne "") {
            Invoke-AWSCommand -Command "aws ec2 delete-route-table --region $region --route-table-id $rt" -Description "Deleting route table $rt"
        }
    }
} else {
    Write-Host "No custom route tables found." -ForegroundColor Gray
}

# Step 6: Detach and Delete Internet Gateway
Write-Host "`n=== Step 6: Deleting Internet Gateway ===" -ForegroundColor Cyan
$igw = aws ec2 describe-internet-gateways --region $region --filters "Name=attachment.vpc-id,Values=$vpcId" --query "InternetGateways[].InternetGatewayId" --output text

if ($igw -and $igw.Trim() -ne "") {
    Invoke-AWSCommand -Command "aws ec2 detach-internet-gateway --region $region --internet-gateway-id $igw --vpc-id $vpcId" -Description "Detaching IGW $igw"
    Invoke-AWSCommand -Command "aws ec2 delete-internet-gateway --region $region --internet-gateway-id $igw" -Description "Deleting IGW $igw"
} else {
    Write-Host "No internet gateway found." -ForegroundColor Gray
}

# Step 7: Delete VPC
Write-Host "`n=== Step 7: Deleting VPC ===" -ForegroundColor Cyan
Invoke-AWSCommand -Command "aws ec2 delete-vpc --region $region --vpc-id $vpcId" -Description "Deleting VPC $vpcId"

# Step 8: Delete IAM Resources
Write-Host "`n=== Step 8: Deleting IAM Resources ===" -ForegroundColor Cyan
$roleName = "control-node-role"

# Delete instance profiles
$profiles = aws iam list-instance-profiles --query "InstanceProfiles[?contains(InstanceProfileName, 'control-node')].InstanceProfileName" --output text

if ($profiles -and $profiles.Trim() -ne "") {
    foreach ($profile in $profiles.Split()) {
        if ($profile.Trim() -ne "") {
            $role = aws iam get-instance-profile --instance-profile-name $profile --query "InstanceProfile.Roles[0].RoleName" --output text 2>$null
            if ($role -and $role.Trim() -ne "") {
                Invoke-AWSCommand -Command "aws iam remove-role-from-instance-profile --instance-profile-name $profile --role-name $role" -Description "Removing role from instance profile $profile"
            }
            Invoke-AWSCommand -Command "aws iam delete-instance-profile --instance-profile-name $profile" -Description "Deleting instance profile $profile"
        }
    }
}

# Delete role policies and role
$policies = aws iam list-role-policies --role-name $roleName --query "PolicyNames" --output text 2>$null
if ($policies -and $policies.Trim() -ne "") {
    foreach ($policy in $policies.Split()) {
        if ($policy.Trim() -ne "") {
            Invoke-AWSCommand -Command "aws iam delete-role-policy --role-name $roleName --policy-name $policy" -Description "Deleting role policy $policy"
        }
    }
}

$roleExists = aws iam get-role --role-name $roleName 2>$null
if ($roleExists) {
    Invoke-AWSCommand -Command "aws iam delete-role --role-name $roleName" -Description "Deleting IAM role $roleName"
}

# Step 9: Delete Key Pair
Write-Host "`n=== Step 9: Deleting Key Pair ===" -ForegroundColor Cyan
Invoke-AWSCommand -Command "aws ec2 delete-key-pair --region $region --key-name $keyPairName" -Description "Deleting key pair $keyPairName"

# Step 10: Delete Backend Resources (Optional)
if (-not $KeepBackend) {
    Write-Host "`n=== Step 10: Deleting Backend Resources ===" -ForegroundColor Cyan
    
    Invoke-AWSCommand -Command "aws s3 rm s3://$s3Bucket --recursive" -Description "Emptying S3 bucket $s3Bucket"
    Invoke-AWSCommand -Command "aws s3api delete-bucket --bucket $s3Bucket --region $region" -Description "Deleting S3 bucket $s3Bucket"
    Invoke-AWSCommand -Command "aws dynamodb delete-table --table-name $dynamoTable --region $region" -Description "Deleting DynamoDB table $dynamoTable"
} else {
    Write-Host "`n=== Step 10: Skipping Backend Resources ===" -ForegroundColor Yellow
    Write-Host "Backend resources (S3, DynamoDB) will be preserved." -ForegroundColor Yellow
}

Write-Host "`n=== Cleanup Complete! ===" -ForegroundColor Green

if ($WhatIf) {
    Write-Host "`nThis was a DRY RUN. No resources were actually deleted." -ForegroundColor Yellow
    Write-Host "Run without -WhatIf to perform actual deletion." -ForegroundColor Yellow
}
