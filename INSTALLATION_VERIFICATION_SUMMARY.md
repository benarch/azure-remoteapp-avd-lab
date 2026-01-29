# Installation Verification Summary

## What Changed?

This update adds comprehensive verification capabilities to your AVD deployment to help diagnose and fix issues like "no available resources" when launching remote apps.

## New Features Added

### 1. Automated Verification Script ⭐
- **File:** `verify-installation.sh`
- **Purpose:** Automatically checks if applications were successfully installed on session host VMs
- **Usage:** `./verify-installation.sh`

### 2. Enhanced Application Deployment
- **File:** `modules/application-deployment/main.tf`
- **Improvements:**
  - Better error handling (continues on error instead of stopping)
  - Detailed logging to `C:\AVD-Deployment-Logs\` on VMs
  - Success/failure counters for each application
  - More informative output messages
  - Proper exit codes

### 3. Enhanced Terraform Outputs
- **File:** `outputs.tf` and `modules/application-deployment/outputs.tf`
- **New outputs:**
  - `application_deployment_verification` - Instructions for manual verification
  - `run_command_ids` - IDs for checking run command status
  - `run_command_names` - Names for checking run command status

### 4. Comprehensive Documentation
- **VERIFICATION_GUIDE.md** - Complete guide on how to verify installation
- **TROUBLESHOOTING.md** - Detailed troubleshooting for common issues
- **QUICK_REFERENCE.md** - Quick command reference card
- **DIAGNOSING_NO_RESOURCES.md** - Specific guide for your current issue
- **Updated README.md** - Added verification section and links

## How to Use

### Quick Start

After deploying with Terraform:

```bash
# 1. Run verification script
./verify-installation.sh

# 2. Review the output for any failures
# The script shows:
# - ✓ Green checkmarks for success
# - ✗ Red X marks for failures
# - Detailed logs and error messages
```

### What the Script Checks

1. ✅ Azure CLI is installed and authenticated
2. ✅ Terraform state exists with deployment info
3. ✅ Resource group exists
4. ✅ VMs exist and are running
5. ✅ Run command completed (application installation)
6. ✅ Applications were installed successfully
7. ✅ AVD agent extensions are installed

### Interpreting Results

#### ✅ Success Output
```
✓ Application deployment completed successfully

Last lines of output:
  Successful installations: 7
  Failed installations: 0
  ✓ Application deployment completed successfully!
```

**Action:** Your deployment is good! If you still can't launch apps:
- Check session host registration: See [DIAGNOSING_NO_RESOURCES.md](DIAGNOSING_NO_RESOURCES.md)
- Verify user permissions
- Wait a few more minutes for registration to complete

#### ❌ Failure Output
```
✗ Application deployment failed or is still running

Error output:
  Chocolatey installation failed: Unable to connect to remote server
```

**Action:** Follow the resolution steps in [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or [DIAGNOSING_NO_RESOURCES.md](DIAGNOSING_NO_RESOURCES.md)

## Manual Verification

If you prefer manual checks or the script doesn't work:

```bash
# Get deployment info
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
VM_NAME=$(terraform output -json session_host_vm_names | jq -r '.[0]')

# Check run command output
az vm run-command show \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name avd-app-deployment \
  --instance-view \
  --query "instanceView.{State:executionState, ExitCode:exitCode, Output:output}" -o json
```

See [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for more commands.

## Fixing "No Available Resources" Issue

Your specific issue has a dedicated guide: **[DIAGNOSING_NO_RESOURCES.md](DIAGNOSING_NO_RESOURCES.md)**

Common causes and quick fixes:

### Cause 1: Applications Not Installed
**Fix:**
```bash
# Option A: Force re-run via Terraform
terraform taint 'module.application_deployment.azurerm_virtual_machine_run_command.app_deployment[0]'
terraform apply -var-file=terraform.tfvars.dev

# Option B: Manual install via RDP
# Connect to VM and run PowerShell script (see DIAGNOSING_NO_RESOURCES.md)
```

### Cause 2: Session Host Not Registered
**Check:**
```bash
az desktopvirtualization sessionhost list \
  -g "$RESOURCE_GROUP" \
  --host-pool-name "$HOST_POOL" -o table
```

Expected status: `Available`

**Fix:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) → "AVD Agent Not Registered"

### Cause 3: VM Not Running
**Fix:**
```bash
az vm start -g "$RESOURCE_GROUP" -n "$VM_NAME"
```

## Logging Improvements

The enhanced deployment script now creates detailed logs on each VM:

**Location:** `C:\AVD-Deployment-Logs\app-deployment-<timestamp>.log`

**To view:**
1. RDP to the session host VM
2. Navigate to `C:\AVD-Deployment-Logs\`
3. Open the most recent log file
4. Look for errors or failed installations

**Log includes:**
- Timestamp for each step
- Chocolatey installation status
- Each application installation result
- Detailed error messages if any failures
- Final summary with success/failure counts

## Documentation Structure

```
avd-lab1/
├── README.md                      # Main deployment guide
├── verify-installation.sh         # Verification script ⭐
├── VERIFICATION_GUIDE.md          # How to verify installation ⭐
├── TROUBLESHOOTING.md             # Solutions for common issues ⭐
├── DIAGNOSING_NO_RESOURCES.md     # Fix for your specific issue ⭐
├── QUICK_REFERENCE.md             # Quick command reference
└── DEPLOYMENT_CHECKLIST.md        # Step-by-step checklist
```

**Start here:**
- Having issues? → [DIAGNOSING_NO_RESOURCES.md](DIAGNOSING_NO_RESOURCES.md)
- Want to verify? → Run `./verify-installation.sh` or see [VERIFICATION_GUIDE.md](VERIFICATION_GUIDE.md)
- Need commands? → [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- Other problems? → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Next Steps

1. **Run the verification script:**
   ```bash
   ./verify-installation.sh
   ```

2. **If applications failed to install:**
   - See [DIAGNOSING_NO_RESOURCES.md](DIAGNOSING_NO_RESOURCES.md) for step-by-step fixes

3. **If session hosts not registered:**
   - Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) → "AVD Agent Not Registered"

4. **If still having issues:**
   - Collect diagnostic info:
     ```bash
     ./verify-installation.sh > verification-output.txt 2>&1
     terraform output -json > terraform-outputs.json
     ```
   - Review the troubleshooting guides
   - Open an issue with the diagnostic files

## Summary of Changes

**Files Modified:**
- `modules/application-deployment/main.tf` - Enhanced error handling and logging
- `modules/application-deployment/outputs.tf` - Added verification outputs
- `outputs.tf` - Exposed verification information
- `README.md` - Added verification section and documentation links

**Files Added:**
- `verify-installation.sh` - Automated verification script
- `VERIFICATION_GUIDE.md` - Complete verification guide
- `TROUBLESHOOTING.md` - Comprehensive troubleshooting
- `QUICK_REFERENCE.md` - Command reference
- `DIAGNOSING_NO_RESOURCES.md` - Specific issue diagnostic

## Benefits

✅ **Faster Issue Diagnosis** - Know exactly what went wrong and where  
✅ **Better Error Messages** - Clear, actionable error information  
✅ **Automated Verification** - One command to check everything  
✅ **Detailed Logging** - Complete audit trail of installations  
✅ **Comprehensive Documentation** - Multiple guides for different needs  
✅ **Time Savings** - Quick resolution of common issues  

---

**Questions or Issues?**

1. Review [DIAGNOSING_NO_RESOURCES.md](DIAGNOSING_NO_RESOURCES.md) for your specific issue
2. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for general problems
3. Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for quick commands
4. Open an issue with verification results if needed
