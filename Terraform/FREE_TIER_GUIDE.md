# AWS Free Tier Guide for Your DevOps Project

## Current Infrastructure Costs

Your infrastructure is **optimized for AWS Free Tier** usage. Here's the breakdown:

### ✅ FREE Resources (Always)

| Resource | Quantity | Free Tier Limit | Notes |
|---|---|---|---|
| **VPC** | 1 | Unlimited | Completely free |
| **Subnets** | 1 | Unlimited | Completely free |
| **Internet Gateway** | 1 | Unlimited | Completely free |
| **Route Tables** | 1 | Unlimited | Completely free |
| **Security Groups** | 2 | Unlimited | Completely free |
| **IAM Roles & Policies** | 3 | Unlimited | Completely free |

### ✅ FREE Resources (Within Limits)

| Resource | Your Usage | Free Tier Limit | Monthly Cost (in limits) |
|---|---|---|---|
| **EC2 t2.micro** | 3 instances | 750 hours/month (1st year) | $0 |
| **S3 Storage** | ~4 KB (state file) | 5 GB | $0 |
| **S3 Requests** | ~20/month | 20,000 GET, 2,000 PUT | $0 |
| **DynamoDB** | State locking | 25 GB + Read/Write capacity | $0 |
| **Data Transfer OUT** | Minimal | 100 GB/month | $0 |

### 📊 Monthly Cost Breakdown

**Within Free Tier (First 12 months):**
```
EC2 (3 × t2.micro, running  24/7): $0.00   (750 hours free)
S3 (state storage):                 $0.00   (under 5 GB)
DynamoDB (state locking):           $0.00   (minimal usage)
VPC & Network:                      $0.00   (always free)
----------------------------------------
TOTAL:                              $0.00/month
```

**After Free Tier Expires:**
```
EC2 (3 × t2.micro @ ~$0.0116/hour):  ~$25/month
S3 (state storage):                   $0.02/month
DynamoDB (state locking):             $0.00/month
VPC & Network:                        $0.00/month
----------------------------------------
TOTAL:                               ~$25/month
```

---

## Optimization Tips to Stay FREE

### 1. **EC2 Instance Management**

❌ **DON'T**: Run more than 750 EC2 hours/month total
- 3 instances × 24 hours × 30 days = 2,160 hours (over limit!)

✅ **DO**: Manage instance runtime carefully
- **Option A**: Run 1 instance 24/7 (750 hours) — FREE
- **Option B**: Run 3 instances part-time (250 hours each) — FREE
- **Option C**: Stop instances when not needed

**How to stay within Free Tier with 3 instances:**
```powershell
# Stop instances when not in use
aws ec2 stop-instances --instance-ids <INSTANCE_IDS>

# Start when needed
aws ec2 start-instances --instance-ids <INSTANCE_IDS>
```

### 2. **Use Spot Instances (Advanced)**

For non-production environments:
- Spot instances can be up to 90% cheaper
- Great for testing/development
- Not recommended for production

### 3. **S3 Cost Management**

Your state file is tiny (~4 KB), so S3 costs are negligible.

✅ Already optimized:
- Versioning enabled (good for recovery)
- Server-side encryption (no extra cost)
- No Intelligent-Tiering needed (file too small)

### 4. **DynamoDB Optimization**

Your setup uses **Pay-per-request** billing:
- Perfect for state locking (minimal usage)
- Costs: ~$0.000000125 per request
- Your usage: ~20 requests/month = $0.00

✅ Already optimized

### 5. **Network/Data Transfer**

Free Tier includes:
- 100 GB data transfer OUT per month
- Unlimited data transfer IN
- Traffic between AWS services in same region

⚠️ **Watch out for:**
- Data transfer to internet (over 100 GB)
- Cross-region traffic

---

## GitHub Actions Free Tier

| Resource | Free Tier Limit | Your Usage | Cost |
|---|---|---|---|
| **GitHub Actions minutes** | 2,000 minutes/month | ~5-10 min/deployment | $0 |
| **GitHub Actions storage** | 500 MB | Minimal | $0 |

Your workflows are well within limits!

---

## Cost Monitoring Setup

### Enable AWS Budgets (Free)

1. Go to AWS Billing Console → Budgets
2. Create a budget alert for $5/month
3. Get email notifications when approaching limit

```bash
# Or use AWS CLI:
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json \
  --notifications-with-subscribers file://notification.json
```

### Check Current Costs

```powershell
# View current month's costs
aws ce get-cost-and-usage \
  --time-period Start=$(Get-Date -Format yyyy-MM-01),End=$(Get-Date -Format yyyy-MM-dd) \
  --granularity MONTHLY \
  --metrics "UnblendedCost"
```

---

## Recommendations for FREE Usage

### ✅ Recommended Configuration (100% Free)

```hcl
# In main.tf, use only 1 control node, no workers
module "controlnode" {
  source = "./modules/Controlnode"
  ...
}

# Comment out workers to stay under 750 hours/month
# module "webserver" {
#   count = 2
#   ...
# }
```

This gives you:
- 1 control node running 24/7 (750 hours) = FREE
- Can deploy workers on-demand when needed

### ⚠️ Current Configuration (Exceeds Free Tier)

```hcl
# 1 control node + 2 webservers = 3 instances
# 3 × 750 hours = 2,250 hours/month
# 2,250 - 750 (free) = 1,500 billable hours
# 1,500 hours × $0.0116/hour = ~$17.40/month
```

---

## Fresh Deploy Strategy

Since you're doing a fresh deploy from GitHub Actions:

### Before Deploying

1. **Re-create backend infrastructure:**
   ```bash
   cd Terraform
   .\create-backend-infra.ps1
   ```

2. **Commit & push changes:**
   ```bash
   git add .
   git commit -m "chore: Clean deploy with remote state backend"
   git push origin main
   ```

3. **GitHub Actions will:**
   - Create S3 bucket & DynamoDB table
   - Create all infrastructure
   - Store state in S3
   - No "resource exists" errors!

### Cost-Saving Option

**If you want to stay 100% FREE**, modify before deploying:

```hcl
# In main.tf, reduce to 1 instance:
module "webserver" {
  source = "./modules/Workernode"
  count  = 0  # Changed from 2 to 0 (no workers for now)
  ...
}
```

Then deploy workers only when needed:
```hcl
count = 2  # Deploy workers
```

Push, let GitHub Actions deploy, then:
```hcl
count = 0  # Remove workers
```

Push again to auto-destroy workers.

---

## Summary

**Your Questions Answered:**

### "Is there any solution not to pay money?"

✅ **YES!** Multiple options:

1. **Run only 1 instance 24/7** (750 hours = Free)
2. **Run 3 instances part-time** (stop when not needed)
3. **Use scheduled start/stop** (automated with Lambda - also free tier!)
4. **Deploy on-demand** (only when testing/demoing)

### "Go with free AWS tier?"

✅ **You're already using Free Tier eligible resources!**

The issue isn't what you're using, it's **how much time** you run them:
- Current: 3 instances × 24/7 = ~$17/month
- Optimized: 1 instance × 24/7 = $0/month (first year)
- On-demand: Start/stop as needed = $0/month (first year)

---

## Next Steps

1. Push your code to GitHub
2. GitHub Actions will deploy fresh infrastructure
3. Monitor AWS costs in Billing Console
4. Set up budget alerts
5. Consider stopping instances when not actively using them

🎉 **You're all set for a free-tier compliant deployment!**
