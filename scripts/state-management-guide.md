# Terraform State Management & Recovery Guide

A comprehensive guide for managing Terraform state, detecting drift, and recovering from common issues.

## Table of Contents
1. [Detecting State Drift](#detecting-state-drift)
2. [Handling Orphaned Resources](#handling-orphaned-resources)
3. [State Corruption Recovery](#state-corruption-recovery)
4. [Clearing Stuck Locks](#clearing-stuck-locks)
5. [Best Practices](#best-practices)

---

## Detecting State Drift

State drift occurs when the real-world infrastructure differs from what Terraform thinks it manages.

### Check What Terraform Manages

```bash
cd Terraform
terraform state list
```

This shows all resources currently tracked in your state file.

### Detect Changes Between State and Reality

```bash
terraform plan -refresh-only
```

This command compares the state file with actual AWS resources and shows what changed.

### Update State to Match Reality

```bash
terraform apply -refresh-only -auto-approve
```

This updates your state file to reflect the current state of resources in AWS **without making any infrastructure changes**.

---

## Handling Orphaned Resources

Orphaned resources fall into two categories:

### Scenario 1: Resource Deleted from AWS (but still in state)

**Symptoms**: `terraform plan` shows errors like "resource not found"

**Solution**: Remove from state

```bash
# Find the resource in state
terraform state list | grep <resource_name>

# Remove it
terraform state rm module.controlnode.aws_instance.control_node

# Verify it's gone
terraform state list
```

**Example**:
```bash
# EC2 instance was manually deleted from AWS Console
terraform state rm module.controlnode.aws_instance.control_node
```

### Scenario 2: Resource Exists in AWS (but not in state) - "Zombie Resource"

**Symptoms**: "Duplicate Resource" or "Already exists" errors when running `terraform apply`

**Solution**: Import into state

```bash
# Import the resource
terraform import <resource_address> <resource_id>

# Verify it's imported
terraform state list | grep <resource_name>
```

**Example**:
```bash
# EC2 instance exists but not tracked
terraform import module.controlnode.aws_instance.control_node i-0123456789abcdef0

# Key pair exists but not tracked
terraform import aws_key_pair.deployer deployer-key
```

### Finding Resource IDs for Import

#### EC2 Instances
```bash
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

#### VPCs
```bash
aws ec2 describe-vpcs \
  --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

#### Security Groups
```bash
aws ec2 describe-security-groups \
  --query 'SecurityGroups[*].[GroupId,GroupName]' \
  --output table
```

#### Key Pairs
```bash
aws ec2 describe-key-pairs \
  --query 'KeyPairs[*].[KeyPairId,KeyName]' \
  --output table
```

#### S3 Buckets
```bash
aws s3 ls
```

#### DynamoDB Tables
```bash
aws dynamodb list-tables
```

---

## State Corruption Recovery

### Always Backup First!

State files are versioned in S3, but create a manual backup:

```bash
# Download current state
aws s3 cp s3://<bucket-name>/devops-project/terraform.tfstate \
  ./backup-state-$(date +%Y%m%d-%H%M%S).tfstate
```

### List Available Versions in S3

```bash
aws s3api list-object-versions \
  --bucket devops-project-terraform-state-<ACCOUNT_ID> \
  --prefix devops-project/terraform.tfstate
```

### Restore from a Specific Version

```bash
# Download specific version
aws s3api get-object \
  --bucket devops-project-terraform-state-<ACCOUNT_ID> \
  --key devops-project/terraform.tfstate \
  --version-id <VERSION_ID> \
  restored-state.tfstate

# Manually upload if needed (use with caution!)
aws s3 cp restored-state.tfstate \
  s3://devops-project-terraform-state-<ACCOUNT_ID>/devops-project/terraform.tfstate
```

---

## Clearing Stuck Locks

If Terraform operations fail with "state is locked", clear the lock:

```bash
# Get your bucket name
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="devops-project-terraform-state-$ACCOUNT_ID"

# The lock ID is usually shown in the error message
LOCK_ID="$BUCKET_NAME/devops-project/terraform.tfstate"

# Delete the lock
aws dynamodb delete-item \
  --table-name terraform-state-locks \
  --key "{\"LockID\": {\"S\": \"$LOCK_ID\"}}"
```

**Note**: Only do this if you're **certain** no other Terraform operation is running!

---

## Best Practices

### 1. Never Manually Edit State Files
Always use `terraform state` commands. Direct editing can corrupt the state.

### 2. Always Refresh Before Operations
```bash
terraform plan -refresh-only  # Check for drift first
terraform plan                # Then plan changes
```

### 3. Use Version Control
- S3 versioning is enabled for your state bucket
- You can roll back to any previous version
- Keep backups of critical state files locally

### 4. Import Before Create
If a resource already exists in AWS, import it instead of trying to recreate it:

```bash
terraform import <resource_type>.<name> <resource_id>
```

### 5. Avoid Auto-Destroy on Failure
- Never run `terraform destroy` immediately after a failed `apply`
- Inspect the state first
- Understand what went wrong
- Manual intervention prevents cascading failures

### 6. Tag Everything
Use consistent tags like `ManagedBy=Terraform` to easily identify managed resources:

```hcl
tags = {
  Name        = "my-resource"
  ManagedBy   = "Terraform"
  Environment = "Production"
}
```

### 7. Use Workspaces or Separate State Files
For multiple environments (dev/staging/prod), use either:

- **Workspaces**: `terraform workspace new dev`
- **Separate backends**: Different state paths per environment

### 8. Regular State Audits
Periodically check for orphaned resources:

```bash
bash scripts/list-orphaned-resources.sh
```

---

## Useful Commands Cheat Sheet

```bash
# List all resources in state
terraform state list

# Show details of a specific resource
terraform state show <resource_address>

# Remove resource from state (doesn't delete from AWS)
terraform state rm <resource_address>

# Import resource into state
terraform import <resource_address> <resource_id>

# Move/rename resource in state
terraform state mv <old_address> <new_address>

# Refresh state file
terraform apply -refresh-only -auto-approve

# Show current state in JSON format
terraform show -json

# Validate configuration
terraform validate

# Format configuration files
terraform fmt -recursive
```

---

## Getting Help

- **Terraform State Documentation**: https://developer.hashicorp.com/terraform/cli/commands/state
- **AWS Provider Import Guide**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Your Orphaned Resources Script**: `bash scripts/list-orphaned-resources.sh`
- **Manual Backend Setup**: `bash scripts/setup-terraform-backend.sh`

---

## Emergency Procedures

### Total State Loss
If state file is completely lost or corrupted beyond recovery:

1. **Don't panic** - Resources still exist in AWS
2. **Create minimal state**:
   ```bash
   cd Terraform
   rm -rf .terraform terraform.tfstate*
   terraform init -backend-config="bucket=$TF_BACKEND_BUCKET" \
     -backend-config="dynamodb_table=terraform-state-locks" \
     -backend-config="region=us-east-1"
   ```
3. **Import resources one by one**:
   ```bash
   terraform import aws_instance.example i-abc123
   ```
4. **Verify with plan**:
   ```bash
   terraform plan
   ```

### Cannot Destroy Resources
If `terraform destroy` fails:

1. Try with parallelism=1:
   ```bash
   terraform destroy -parallelism=1
   ```
2. Target specific resources:
   ```bash
   terraform destroy -target=aws_instance.example
   ```
3. Last resort - manual cleanup via AWS Console

---

**Remember**: State management is critical. When in doubt, make a backup before making changes!
