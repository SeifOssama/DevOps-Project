# 🚀 Fresh AWS Deployment Guide

This guide will help you achieve a clean deployment on fresh AWS infrastructure after the workflow restructuring.

## Prerequisites

Before starting, ensure you have:
- ✅ AWS account with appropriate permissions
- ✅ GitHub repository secrets configured:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `SSH_PRIVATE_KEY`
  - `SSH_PUBLIC_KEY`

---

## Step 1: Complete Cleanup (If Needed)

If you have existing infrastructure from previous deployments:

### 1.1 Run Destroy Workflow

1. Go to **Actions** → **Destroy All Infrastructure**
2. Click **"Run workflow"**
3. Type `destroy` in the confirmation field
4. Click **"Run workflow"**
5. Wait for completion (~3-5 minutes)

### 1.2 Verify Destruction

Check the workflow logs to confirm:
- ✅ All resources successfully destroyed
- ✅ No orphaned resources warning

### 1.3 Manual Cleanup (Only if needed)

If the destroy workflow reports orphaned resources:

1. **AWS Console → EC2**:
   - Terminate any instances with tag `ManagedBy: Terraform`
   
2. **AWS Console → VPC**:
   - Delete security groups (if any remain)
   - Delete VPC named `devops-project-vpc` (if exists)

3. **Optional - Clear State** (only if you encounter persistent errors):
   ```bash
   # AWS S3 Console
   # Bucket: devops-project-terraform-state-<your-account-id>
   # → Empty the "devops-project/" folder
   
   # AWS DynamoDB Console
   # Table: terraform-state-locks
   # → Delete any lock entries
   ```

---

## Step 2: Fresh Deployment

### 2.1 Run Deploy Workflow

1. Go to **Actions** → **Deploy Infrastructure & Services**
2. Click **"Run workflow"**
3. Select branch: `main`
4. Click **"Run workflow"**
5. Monitor progress (~8-12 minutes)

### 2.2 Deployment Phases

The workflow will execute these phases automatically:

| Phase | Description | Duration |
|-------|-------------|----------|
| **Phase 0** | Setup & Preflight Checks | ~1 min |
| **Phase 1** | Infrastructure Provisioning | ~3-4 min |
| **Phase 2** | Ansible Environment Setup | ~2 min |
| **Phase 2.5** | Docker Pre-Installation | ~1-2 min |
| **Phase 3** | Monitoring Node Configuration | ~2-3 min |
| **Phase 4** | Webserver Configuration | ~1-2 min |
| **Phase 5** | Monitoring Integration | ~1 min |
| **Phase 6** | Final Validation & Summary | ~1 min |

### 2.3 Automatic Cleanup on Failure

If **ANY phase fails**, the workflow will:
1. ⚠️ Automatically trigger cleanup job
2. 🧹 Destroy all partially created resources
3. 🔓 Clear any stuck Terraform locks
4. ✅ Leave your AWS account clean

**You can then safely re-run the deployment!**

---

## Step 3: Verify Deployment

### 3.1 Check Workflow Output

At the end of successful deployment, you'll see:

```
╔════════════════════════════════════════════════════════════════╗
║                  🎉 DEPLOYMENT SUCCESSFUL 🎉                  ║
╚════════════════════════════════════════════════════════════════╝

📍 INFRASTRUCTURE ENDPOINTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Prometheus:    http://<MONITORING-IP>:9090
📊 Grafana:       http://<MONITORING-IP>:3000
   └─ Username:   admin
   └─ Password:   admin
🚨 Alertmanager:  http://<MONITORING-IP>:9093

🌐 WEBSERVERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Webserver-0:  http://<WEBSERVER-IP-1>
  Webserver-1:  http://<WEBSERVER-IP-2>
```

### 3.2 Access Your Services

1. **Grafana Dashboard**:
   - URL: `http://<MONITORING-IP>:3000`
   - Username: `admin`
   - Password: `admin`
   - Browse to explore pre-configured dashboards

2. **Prometheus Metrics**:
   - URL: `http://<MONITORING-IP>:9090`
   - Check targets: `/targets`
   - Check alerts: `/alerts`

3. **Webservers**:
   - URL: `http://<WEBSERVER-IP>/`
   - Should display Apache default or custom page

4. **Alertmanager**:
   - URL: `http://<MONITORING-IP>:9093`

### 3.3 Health Checks

All these should return healthy:
- ✅ Prometheus: `http://<IP>:9090/-/healthy`
- ✅ Grafana: `http://<IP>:3000/api/health`
- ✅ Alertmanager: `http://<IP>:9093/-/healthy`

---

## Common Issues & Solutions

### Issue 1: Deployment Fails at Infrastructure Phase

**Symptoms**: Terraform apply fails with "Resource already exists"

**Solution**:
1. Run the Destroy workflow
2. Wait for completion
3. Re-run Deploy workflow

### Issue 2: Stuck Terraform Locks

**Symptoms**: Error message about "state locked"

**Solution**:
The Deploy workflow automatically clears stuck locks in Phase 1.
If issue persists:
1. Go to AWS DynamoDB Console
2. Table: `terraform-state-locks`
3. Delete the lock item
4. Re-run Deploy workflow

### Issue 3: SSH Connection Issues

**Symptoms**: Ansible fails to connect to instances

**Solution**:
1. Verify GitHub Secrets:
   - `SSH_PRIVATE_KEY` matches `SSH_PUBLIC_KEY`
   - Keys are formatted correctly (PEM format)
2. Check security group allows SSH (port 22)
3. Wait longer for instances to boot (Phase 2 has 30s wait)

### Issue 4: Manually Deleted Resources

**Symptoms**: Terraform errors about resources not found

**Solution**:
1. Run the Destroy workflow (it handles this gracefully)
2. The destroy workflow will:
   - Refresh state to detect deletions
   - Skip already-deleted resources
   - Clean up remaining resources
3. Deploy fresh infrastructure

### Issue 5: Partial Deployment Remains

**Symptoms**: Some resources still exist after failed deployment

**Solution**:
The cleanup job should automatically handle this, but if not:
1. Manually run Destroy workflow
2. Check AWS Console for orphaned resources
3. Manually terminate/delete if needed

---

## Understanding the 3 Workflows

### 1️⃣ **Deploy Infrastructure & Services**
- **Purpose**: Complete infrastructure deployment
- **When to use**: Initial deployment or updates
- **Auto-cleanup**: YES (on any failure)
- **Duration**: ~8-12 minutes

### 2️⃣ **Destroy All Infrastructure**
- **Purpose**: Complete teardown
- **When to use**: Clean up, cost reduction, fresh start
- **Confirmation**: Required (type "destroy")
- **Preserves**: S3 state bucket & DynamoDB table
- **Duration**: ~3-5 minutes

### 3️⃣ **Validate Infrastructure Code**
- **Purpose**: Code quality checks
- **When to use**: PRs, before deployment
- **Runs automatically**: On PRs to main branch
- **Validates**: Terraform, Ansible, YAML, Shell scripts

---

## Cost Management

### Free Tier Resources

The deployment uses:
- **EC2**: 3x t2.micro instances (750 hours/month free tier)
- **VPC**: Free
- **S3**: < 1GB storage (free tier)
- **DynamoDB**: < 25GB (free tier)

### Minimize Costs

To avoid charges when not in use:

1. **Destroy infrastructure**:
   ```
   Actions → Destroy All Infrastructure → Type "destroy" → Run
   ```

2. **State preserved**:
   - S3 bucket and DynamoDB remain
   - Next deployment uses existing state
   - No data loss

3. **Re-deploy when needed**:
   ```
   Actions → Deploy Infrastructure & Services → Run
   ```

---

## Next Steps

After successful deployment:

1. **Customize Grafana**:
   - Change admin password
   - Create custom dashboards
   - Configure alerts

2. **Deploy Your Application**:
   - Update webserver playbooks
   - Deploy your custom applications
   - Add monitoring for your apps

3. **Set Up CI/CD**:
   - Enable automatic deployments on push to main
   - Uncomment lines 11-13 in `deploy.yml`

4. **Backup Important Data**:
   - Export Grafana dashboards
   - Save Prometheus configurations
   - Document custom changes

---

## Support & Troubleshooting

If you encounter issues:

1. **Check workflow logs** in GitHub Actions
2. **Review deployment summary** at end of workflow
3. **Verify AWS Console** for resource states
4. **Run Destroy workflow** for clean slate
5. **Re-deploy** with fresh infrastructure

---

## Workflow Files Reference

- **Deploy**: `.github/workflows/deploy.yml`
- **Destroy**: `.github/workflows/destroy.yml`
- **Validate**: `.github/workflows/validate.yml`

## Terraform Files Reference

- **Main**: `Terraform/main.tf`
- **Backend**: `Terraform/backend.tf`
- **Variables**: `Terraform/variables.tf`
- **Outputs**: `Terraform/output.tf`

---

**Good luck with your deployment! 🚀**
