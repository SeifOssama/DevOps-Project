# GitHub Actions Workflow Update - Ansible Dependencies Fix

## Problem Summary
The GitHub Actions workflow was encountering errors when trying to use Ansible's AWS EC2 dynamic inventory plugin:
- **Root Cause**: Ansible installed via `pipx` was using its own isolated virtual environment (`/opt/pipx/venvs/ansible-core/bin/python`), but `boto3` and `botocore` were not available in that environment.
- **Error**: `Failed to import the required Python library (botocore and boto3)`

## Solution Implemented
**Option 1: Clean Installation Approach (No pipx)**

We replaced the entire Phase 2 Ansible setup with a fresh, clean installation that:
1. Installs all dependencies in the same Python environment
2. Avoids pipx entirely
3. Provides comprehensive version checking and validation

## Changes Made

### Phase 2: Ansible Environment Setup - Restructured

#### Phase 2.1 - Verify Pre-installed Tools ✅
- **Purpose**: Document baseline versions before installation
- **Checks**: Python, Pip, AWS CLI, Ansible (if pre-installed)
- **Output**: Clear visibility of starting state

#### Phase 2.2 - Install Python Dependencies ✅
- **Method**: Uses `python3 -m pip install` (NOT `pip3` or `sudo pip3`)
- **Packages Installed**:
  - `pip` (upgraded first)
  - `boto3>=1.34.0`
  - `botocore>=1.34.0`
  - `ansible>=2.17`
- **Key Benefit**: All packages installed to system Python in one environment

#### Phase 2.3 - Install Ansible Collections ✅
- **Collection**: `amazon.aws`
- **Method**: `ansible-galaxy collection install amazon.aws`
- **Purpose**: Provides AWS EC2 dynamic inventory plugin

#### Phase 2.4 - Verify Complete Installation ✅
- **Comprehensive Checks**:
  - Python version
  - Pip version
  - Ansible version and Python interpreter
  - Boto3 version
  - Botocore version
  - AWS CLI version
  - Ansible collections list
  - AWS EC2 inventory plugin documentation
- **All checks include actual version output for debugging**

#### Phase 2.5 - Test AWS Connectivity ✅
- **Test**: AWS EC2 API access
- **Command**: `aws ec2 describe-instances` with formatted output
- **Purpose**: Verify AWS credentials and connectivity before proceeding

## Removed Components
1. ❌ **Old apt-based Ansible installation** (with ppa:ansible/ansible)
2. ❌ **Conditional boto3/botocore installation** with `--break-system-packages`
3. ❌ **pipx detection and injection logic**
4. ❌ **AWS CLI download and manual installation** (using pre-installed version)
5. ❌ **systemctl daemon-reload** (unnecessary)
6. ❌ **Environment variable for ANSIBLE_PYTHON_INTERPRETER** (not needed with system Python)
7. ❌ **Duplicate package verification steps** (consolidated into Phase 2.4)

## Benefits of This Approach

### ✅ Simplicity
- Single Python environment for all tools
- No complex detection logic for pipx
- Clear, linear installation flow

### ✅ Reliability
- Explicit version requirements ensure compatibility
- All dependencies in same environment
- No environment isolation issues

### ✅ Debuggability
- Comprehensive version output at each step
- Clear separation of installation phases
- Easy to identify which step failed

### ✅ Maintainability
- Clean, readable workflow
- Each phase has a single, clear purpose
- Well-documented with comments

### ✅ Performance
- Reduced from ~200 lines to ~120 lines
- Removed redundant installations (AWS CLI was pre-installed)
- Cleaner execution flow

## Version Requirements
- **Python**: 3.x (pre-installed on GitHub Actions runners)
- **Ansible**: >=2.17
- **Boto3**: >=1.34.0
- **Botocore**: >=1.34.0
- **AWS CLI**: Pre-installed on runners (2.32.17+)

## Testing Strategy
The workflow includes comprehensive testing at each phase:
1. **Pre-flight**: Verify starting state
2. **Installation**: Install all packages
3. **Verification**: Confirm all packages are accessible
4. **Connectivity**: Test AWS API access
5. **Plugin Test**: Verify AWS EC2 inventory plugin works

## Next Steps
1. **Run the workflow** to verify the fix works
2. **Monitor the output** of Phase 2 steps for any issues
3. **Verify** that the AWS EC2 dynamic inventory plugin successfully discovers instances

## Deprecation Warnings (Optional Fix)
The deprecation warnings about `to_text` and `to_native` imports are coming from Ansible core and do not affect functionality. They can be suppressed by adding to `ansible.cfg`:
```ini
[defaults]
deprecation_warnings = False
```

However, these are just warnings and do not cause the workflow to fail.

## Files Modified
- `.github/workflows/deploy.yml` - Phase 2 (lines 309-421) completely rewritten
