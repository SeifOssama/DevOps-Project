#!/bin/bash
# Script to list orphaned AWS resources not tracked in Terraform state

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Orphaned Resource Detection Tool                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

REGION="${AWS_REGION:-us-east-1}"

# ============================================
# 1. Get Terraform State Resources
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Checking Terraform State"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$(dirname "$0")/../Terraform" || {
  echo "❌ Cannot find Terraform directory"
  exit 1
}

# Initialize if needed
if [ ! -d ".terraform" ]; then
  echo "⚠️  Terraform not initialized. Attempting to initialize..."
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="dynamodb_table=${TF_BACKEND_DYNAMODB_TABLE:-terraform-state-locks}" \
    -backend-config="region=${TF_BACKEND_REGION:-us-east-1}" || {
    echo "❌ Failed to initialize Terraform"
    echo "   Set environment variables: TF_BACKEND_BUCKET, TF_BACKEND_DYNAMODB_TABLE, TF_BACKEND_REGION"
    exit 1
  }
fi

echo "📋 Resources in Terraform state:"
STATE_RESOURCES=$(terraform state list 2>/dev/null || echo "")

if [ -z "$STATE_RESOURCES" ]; then
  echo "   ⚠️  No resources in state (empty state or not initialized)"
else
  echo "$STATE_RESOURCES" | sed 's/^/   /'
fi

echo ""
echo "Total: $(echo "$STATE_RESOURCES" | grep -c . || echo 0) resources in state"
echo ""

# ============================================
# 2. Check EC2 Instances
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Checking EC2 Instances"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

AWS_INSTANCES=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:ManagedBy,Values=Terraform" \
            "Name=instance-state-name,Values=running,stopped,stopping,pending" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output text 2>/dev/null || echo "")

if [ -z "$AWS_INSTANCES" ]; then
  echo "✅ No EC2 instances found in AWS"
else
  echo "📋 EC2 Instances in AWS (ManagedBy=Terraform):"
  echo ""
  
  ORPHANED_COUNT=0
  
  while IFS=$'\t' read -r instance_id instance_name state; do
    # Check if instance ID is in state
    if echo "$STATE_RESOURCES" | grep -q "$instance_id"; then
      echo "   ✅ $instance_name ($instance_id) - State: $state - In Terraform state"
    else
      echo "   ⚠️  $instance_name ($instance_id) - State: $state - ORPHANED (not in Terraform state)"
      ORPHANED_COUNT=$((ORPHANED_COUNT + 1))
    fi
  done <<< "$AWS_INSTANCES"
  
  echo ""
  if [ "$ORPHANED_COUNT" -gt 0 ]; then
    echo "🚨 Found $ORPHANED_COUNT orphaned EC2 instance(s)"
  else
    echo "✅ All EC2 instances are tracked in Terraform state"
  fi
fi

echo ""

# ============================================
# 3. Check VPCs
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Checking VPCs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

AWS_VPCS=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --filters "Name=tag:ManagedBy,Values=Terraform" \
  --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' \
  --output text 2>/dev/null || echo "")

if [ -z "$AWS_VPCS" ]; then
  echo "✅ No VPCs found in AWS"
else
  echo "📋 VPCs in AWS (ManagedBy=Terraform):"
  echo ""
  
  while IFS=$'\t' read -r vpc_id vpc_name; do
    if echo "$STATE_RESOURCES" | grep -q "$vpc_id"; then
      echo "   ✅ $vpc_name ($vpc_id) - In Terraform state"
    else
      echo "   ⚠️  $vpc_name ($vpc_id) - ORPHANED (not in Terraform state)"
    fi
  done <<< "$AWS_VPCS"
fi

echo ""

# ============================================
# 4. Check Security Groups
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Checking Security Groups"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

AWS_SGS=$(aws ec2 describe-security-groups \
  --region "$REGION" \
  --filters "Name=tag:ManagedBy,Values=Terraform" \
  --query 'SecurityGroups[*].[GroupId,GroupName]' \
  --output text 2>/dev/null || echo "")

if [ -z "$AWS_SGS" ]; then
  echo "✅ No security groups found in AWS"
else
  echo "📋 Security Groups in AWS (ManagedBy=Terraform):"
  echo ""
  
  while IFS=$'\t' read -r sg_id sg_name; do
    if echo "$STATE_RESOURCES" | grep -q "$sg_id"; then
      echo "   ✅ $sg_name ($sg_id) - In Terraform state"
    else
      echo "   ⚠️  $sg_name ($sg_id) - ORPHANED (not in Terraform state)"
    fi
  done <<< "$AWS_SGS"
fi

echo ""

# ============================================
# 5. Check Key Pairs
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Checking Key Pairs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

AWS_KEYS=$(aws ec2 describe-key-pairs \
  --region "$REGION" \
  --query 'KeyPairs[*].[KeyPairId,KeyName]' \
  --output text 2>/dev/null || echo "")

if [ -z "$AWS_KEYS" ]; then
  echo "✅ No key pairs found in AWS"
else
  echo "📋 Key Pairs in AWS:"
  echo ""
  
  while IFS=$'\t' read -r key_id key_name; do
    if echo "$STATE_RESOURCES" | grep -q "aws_key_pair.*deployer"; then
      echo "   ✅ $key_name ($key_id) - In Terraform state"
    else
      echo "   ⚠️  $key_name ($key_id) - ORPHANED (not in Terraform state)"
    fi
  done <<< "$AWS_KEYS"
fi

echo ""

# ============================================
# Summary
# ============================================
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Detection Complete                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📝 What to do with orphaned resources:"
echo ""
echo "Option 1: Import into Terraform state"
echo "  terraform import <resource_type>.<name> <resource_id>"
echo "  Example: terraform import module.controlnode.aws_instance.control_node i-abc123"
echo ""
echo "Option 2: Remove from Terraform state (if manually deleted from AWS)"
echo "  terraform state rm <resource_type>.<name>"
echo "  Example: terraform state rm module.controlnode.aws_instance.control_node"
echo ""
echo "Option 3: Manually delete from AWS Console"
echo "  If you don't want Terraform to manage it anymore"
echo ""
echo "For detailed instructions, see: scripts/state-management-guide.md"
