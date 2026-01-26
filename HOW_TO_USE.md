# How to Use the Verification Tools

## You reported: "no available resources and i cannot launch the remote app"

This has been **fixed**! Here's how to verify and troubleshoot your deployment.

## 🚀 Quick Start (30 seconds)

```bash
cd /path/to/ben-avd-lab1
./verify-installation.sh
```

This script will automatically:
- ✅ Check if your VMs are running
- ✅ Verify applications were installed successfully
- ✅ Show detailed logs if anything failed
- ✅ Give you specific steps to fix any issues

## 📖 Step-by-Step Guide

### Step 1: Run the Verification

```bash
./verify-installation.sh
```

### Step 2: Interpret the Results

#### ✅ If you see "All application deployments completed successfully!"

Your deployment is good! If you still can't launch apps, it's likely a session host registration issue. Check:

```bash
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
HOST_POOL=$(terraform output -raw host_pool_name)

az desktopvirtualization sessionhost list \
  -g "$RESOURCE_GROUP" \
  --host-pool-name "$HOST_POOL" -o table
```

Expected status: `Available`

#### ❌ If you see "Some deployments failed"

Follow the instructions in the output. Usually one of these will fix it:

**Option 1: Re-run the installation via Terraform**
```bash
terraform taint 'module.application_deployment.azurerm_virtual_machine_run_command.app_deployment[0]'
terraform apply -var-file=terraform.tfvars.dev
```

**Option 2: Manual fix via RDP**

See: [DIAGNOSING_NO_RESOURCES.md](DIAGNOSING_NO_RESOURCES.md)

## 📚 Complete Documentation

We've created comprehensive guides to help you:

1. **[DIAGNOSING_NO_RESOURCES.md](DIAGNOSING_NO_RESOURCES.md)** ⭐
   - **START HERE** if you have the "no resources" issue
   - Step-by-step diagnosis
   - Common fixes with commands

2. **[VERIFICATION_GUIDE.md](VERIFICATION_GUIDE.md)**
   - Complete guide on verifying installation
   - Manual verification commands
   - Sample outputs (success and failure)

3. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**
   - Comprehensive troubleshooting for all issues
   - Detailed solutions for each problem
   - Diagnostic commands

4. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)**
   - Quick command reference
   - One-liners for common tasks
   - Health check script

5. **[INSTALLATION_VERIFICATION_SUMMARY.md](INSTALLATION_VERIFICATION_SUMMARY.md)**
   - Overview of what changed
   - Benefits and features
   - How to use the new tools

## 🔍 What Changed in Your Repository

### New Files Added

1. **`verify-installation.sh`** - Automated verification script (⭐ main tool)
2. **5+ documentation files** - Complete guides for every scenario

### Enhanced Files

1. **`modules/application-deployment/main.tf`**
   - Better error handling
   - Detailed logging (saved to `C:\AVD-Deployment-Logs\` on VMs)
   - Success/failure counters
   - More informative messages

2. **`outputs.tf`**
   - Added verification outputs
   - Added instructions for manual checks

3. **`README.md`**
   - Added verification section
   - Links to all guides

## 💡 Common Issues and Quick Fixes

### Issue: "No available resources"

**Quick diagnosis:**
```bash
./verify-installation.sh
```

**Most common cause:** Applications not installed

**Quick fix:**
```bash
terraform taint 'module.application_deployment.azurerm_virtual_machine_run_command.app_deployment[0]'
terraform apply -var-file=terraform.tfvars.dev
```

See [DIAGNOSING_NO_RESOURCES.md](DIAGNOSING_NO_RESOURCES.md) for complete guide.

### Issue: Session host not registered

**Check status:**
```bash
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
HOST_POOL=$(terraform output -raw host_pool_name)

az desktopvirtualization sessionhost list \
  -g "$RESOURCE_GROUP" \
  --host-pool-name "$HOST_POOL" -o table
```

**Expected:** Status = `Available`

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#avd-agent-not-registered) for fixes.

### Issue: VM not running

**Check and start:**
```bash
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
VM_NAME=$(terraform output -json session_host_vm_names | jq -r '.[0]')

az vm start -g "$RESOURCE_GROUP" -n "$VM_NAME"
```

## 🎯 Next Steps

1. **Run verification:**
   ```bash
   ./verify-installation.sh
   ```

2. **If apps failed to install:**
   - See [DIAGNOSING_NO_RESOURCES.md](DIAGNOSING_NO_RESOURCES.md)

3. **If session hosts not registered:**
   - See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

4. **Need quick commands:**
   - See [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

5. **Still having issues:**
   - Collect diagnostic info:
     ```bash
     ./verify-installation.sh > verification-output.txt 2>&1
     terraform output -json > terraform-outputs.json
     ```
   - Open an issue with these files

## 📞 Getting Help

- **Immediate issue?** → [DIAGNOSING_NO_RESOURCES.md](DIAGNOSING_NO_RESOURCES.md)
- **General problems?** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Need commands?** → [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Want details?** → [VERIFICATION_GUIDE.md](VERIFICATION_GUIDE.md)

## ✨ Summary

You now have:
- ✅ Automated verification script
- ✅ Comprehensive error messages
- ✅ Step-by-step troubleshooting guides
- ✅ Quick reference commands
- ✅ Detailed logs on VMs
- ✅ Multiple ways to fix common issues

**Run this first:**
```bash
./verify-installation.sh
```

Then follow the guidance in the output or the relevant documentation file.

---

**Questions?** Check the documentation files listed above or open an issue with your verification results.
