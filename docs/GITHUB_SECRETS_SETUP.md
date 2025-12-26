# GitHub Secrets Setup Guide

## Required Secrets

Before running the GitHub Actions workflows, you need to configure the following secrets in your GitHub repository.

### How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret below

---

## AWS Credentials

### `AWS_ACCESS_KEY_ID`
**Description**: Your AWS access key ID

**How to get it**:
1. Go to AWS Console →IAM → Users
2. Select your user → Security Credentials
3. Create access key if you don't have one
4. Copy the Access Key ID

**Value**: `AKIA...` (your AWS access key)

---

### `AWS_SECRET_ACCESS_KEY`
**Description**: Your AWS secret access key

**How to get it**:
- Copy from the same location as ACCESS_KEY_ID
- ⚠️ **Important**: This is only shown once when created!

**Value**: `your-secret-access-key`

---

### `AWS_REGION`
**Description**: AWS region where infrastructure will be deployed

**Value**: `us-east-1` (or your preferred region)

> **Note**: Make sure this matches the region in your Terraform configuration!

---

## SSH Keys

### `SSH_PRIVATE_KEY` 
**Description**: SSH private key for accessing EC2 instances

**How to get it**:
```bash
# From your project directory
cat Terraform/ssh/deployer_key
```

**Value**: Copy the **entire** contents including:
```
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

⚠️ **Important**: Include the header/footer lines!

---

### `SSH_PUBLIC_KEY`
**Description**: SSH public key to deploy to EC2 instances

**How to get it**:
```bash
# From your project directory
cat Terraform/ssh/deployer_key.pub
```

**Value**: Copy the entire line, for example:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQAB... user@host
```

---

## Verification

After adding all secrets, you should have **5 secrets** configured:

- ✅ `AWS_ACCESS_KEY_ID`
- ✅ `AWS_SECRET_ACCESS_KEY`
- ✅ `AWS_REGION`
- ✅ `SSH_PRIVATE_KEY`
- ✅ `SSH_PUBLIC_KEY`

---

## Security Best Practices

1. **Never commit secrets** to the repository
2. **Use AWS IAM user** with minimum required permissions
3. **Rotate keys regularly**
4. **Delete old access keys** after rotation
5. **Never share secrets** in chat/email

---

## Testing

To verify secrets are configured correctly:

1. Go to **Actions** tab in GitHub
2. Select **Deploy Infrastructure & Services** workflow
3. Click **Run workflow**
4. Check the "Phase 0 - Verify AWS Credentials" and "Verify SSH Key Loaded" steps

If both pass, your secrets are configured correctly! ✅

---

## Troubleshooting

### Error: "AWS credentials not found"
**Solution**: Check that `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set correctly

### Error: "Permission denied (publickey)"
**Solution**: Verify `SSH_PRIVATE_KEY` includes BEGIN/END lines and has correct format

### Error: "InvalidKeyPair"
**Solution**: Ensure `SSH_PUBLIC_KEY` matches the private key format
