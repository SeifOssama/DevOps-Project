# GitHub Secrets Configuration Guide

## Required Secrets for Terraform Backend

After running the `setup-terraform-backend.sh` script, you need to add these secrets to your GitHub repository.

### How to Add Secrets

1. Go to your GitHub repository
2. Click on **Settings**
3. In the left sidebar, click **Secrets and variables** > **Actions**
4. Click **New repository secret**
5. Add each of the following secrets:

---

## Backend Configuration Secrets

### 1. `TF_BACKEND_BUCKET`

**Description**: S3 bucket name for storing Terraform state  
**Value**: `devops-project-terraform-state-<YOUR_AWS_ACCOUNT_ID>`

**Example**: `devops-project-terraform-state-724772082485`

**How to get this value**:
```bash
aws sts get-caller-identity --query Account --output text
# Output: 724772082485

# Your bucket name is:
# devops-project-terraform-state-724772082485
```

---

### 2. `TF_BACKEND_DYNAMODB_TABLE`

**Description**: DynamoDB table name for state locking  
**Value**: `terraform-state-locks`

This is a static value - always use `terraform-state-locks`

---

### 3. `TF_BACKEND_REGION`

**Description**: AWS region where backend resources are located  
**Value**: `us-east-1`

This is a static value - always use `us-east-1` (or whatever region you chose)

---

## Existing Secrets (Already Configured)

Make sure these are still configured in your repository:

### 4. `AWS_ACCESS_KEY_ID`
Your AWS access key for GitHub Actions

### 5. `AWS_SECRET_ACCESS_KEY`
Your AWS secret access key for GitHub Actions

### 6. `SSH_PRIVATE_KEY`
Private SSH key for EC2 instance access

### 7. `SSH_PUBLIC_KEY`
Public SSH key for EC2 key pair creation

---

## Verification

After adding all secrets, verify they're configured:

1. Go to **Settings** > **Secrets and variables** > **Actions**
2. You should see 7 repository secrets:
   - ✅ `AWS_ACCESS_KEY_ID`
   - ✅ `AWS_SECRET_ACCESS_KEY`
   - ✅ `SSH_PRIVATE_KEY`
   - ✅ `SSH_PUBLIC_KEY`
   - ✅ `TF_BACKEND_BUCKET`
   - ✅ `TF_BACKEND_DYNAMODB_TABLE`
   - ✅ `TF_BACKEND_REGION`

---

## Quick Setup Script

Run this script to get the exact values you need:

```bash
#!/bin/bash

echo "═══════════════════════════════════════════════════════"
echo "GitHub Secrets Values"
echo "═══════════════════════════════════════════════════════"
echo ""

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="devops-project-terraform-state-$ACCOUNT_ID"

echo "Add these secrets to GitHub:"
echo ""
echo "Secret: TF_BACKEND_BUCKET"
echo "Value:  $BUCKET_NAME"
echo ""
echo "Secret: TF_BACKEND_DYNAMODB_TABLE"
echo "Value:  terraform-state-locks"
echo ""
echo "Secret: TF_BACKEND_REGION"
echo "Value:  us-east-1"
echo ""
echo "═══════════════════════════════════════════════════════"
```

---

## Usage in GitHub Actions

The secrets are used in the workflow like this:

```yaml
- name: Terraform Init
  run: |
    cd Terraform
    terraform init \
      -backend-config="bucket=${{ secrets.TF_BACKEND_BUCKET }}" \
      -backend-config="dynamodb_table=${{ secrets.TF_BACKEND_DYNAMODB_TABLE }}" \
      -backend-config="region=${{ secrets.TF_BACKEND_REGION }}"
```

This approach keeps your AWS account ID and other configuration details out of your codebase!
