# Quick Import - IAM Instance Profile

The IAM instance profile also existed from previous runs.

## What Was Imported

✅ **IAM Instance Profile**
- Resource: `module.controlnode.aws_iam_instance_profile.control_node_profile`
- AWS Name: `monitoring-node-profile`
- Status: Successfully imported

## Complete List of Imported Resources

1. ✅ `aws_key_pair.deployer` → `deployer-key`
2. ✅ `module.controlnode.aws_iam_role.control_node_role` → `monitoring-node-role`
3. ✅ `module.controlnode.aws_iam_instance_profile.control_node_profile` → `monitoring-node-profile`

## Next Steps

**Re-run the GitHub Actions workflow** - Should work now!

If you get another "already exists" error:
1. Note the resource name from the error
2. Run: `terraform import <resource_address> <resource_name>`
3. Re-run the workflow

## Quick Import Commands

If you need to import more resources:

```powershell
cd Terraform

# IAM instance profile (already done)
terraform import module.controlnode.aws_iam_instance_profile.control_node_profile monitoring-node-profile

# If worker node resources exist:
terraform import module.workernode[0].aws_iam_role.worker_role worker-node-role
terraform import module.workernode[0].aws_iam_instance_profile.worker_profile worker-node-profile

# Verify state
terraform state list
```

The workflow should succeed now with these 3 resources imported!
