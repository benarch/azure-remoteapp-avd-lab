# Quick Reference - AVD Verification Commands

## 🚀 Quick Start

```bash
# Run the comprehensive verification script
./verify-installation.sh
```

## 📋 Essential Commands

### Get Resource Information
```bash
# Get resource group name
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# Get VM names
VM_NAME=$(terraform output -json session_host_vm_names | jq -r '.[0]')

# Get host pool name
HOST_POOL=$(terraform output -raw host_pool_name)
```

### Check VM Status
```bash
# Quick status check
az vm list -g "$RESOURCE_GROUP" --show-details \
  --query "[].{Name:name, PowerState:powerState}" -o table

# Detailed VM status
az vm get-instance-view -g "$RESOURCE_GROUP" -n "$VM_NAME" \
  --query "instanceView.statuses" -o table
```

### Check Run Command (Application Installation)
```bash
# Check if run command exists
az vm run-command show \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name avd-app-deployment \
  --query "{Name:name, State:provisioningState}" -o table

# View full output with logs
az vm run-command show \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name avd-app-deployment \
  --instance-view \
  --query "instanceView.{State:executionState, ExitCode:exitCode, Output:output}" -o json

# Just the output text
az vm run-command show \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name avd-app-deployment \
  --instance-view \
  --query "instanceView.output" -o tsv
```

### Check Session Host Registration
```bash
# List all session hosts
az desktopvirtualization sessionhost list \
  -g "$RESOURCE_GROUP" \
  --host-pool-name "$HOST_POOL" \
  --query "[].{Name:name, Status:status, Sessions:sessions}" -o table

# Detailed session host info
az desktopvirtualization sessionhost show \
  -g "$RESOURCE_GROUP" \
  --host-pool-name "$HOST_POOL" \
  --name "<session-host-name>"
```

### Check User Permissions
```bash
# Get user email from Terraform
USER_EMAIL=$(terraform output -raw assigned_user_email)

# Check role assignments
az role assignment list \
  --assignee "$USER_EMAIL" \
  --query "[?roleDefinitionName=='Desktop Virtualization User'].{Role:roleDefinitionName, Scope:scope}" -o table
```

### Check VM Extensions
```bash
# List all extensions
az vm extension list \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --query "[].{Name:name, State:provisioningState, Type:typeHandlerVersion}" -o table

# Get specific extension details
az vm extension show \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name "avd-hostpool-register"
```

## 🔧 Troubleshooting One-Liners

### Start a stopped VM
```bash
az vm start -g "$RESOURCE_GROUP" -n "$VM_NAME"
```

### Restart a VM
```bash
az vm restart -g "$RESOURCE_GROUP" -n "$VM_NAME"
```

### Get VM power state
```bash
az vm get-instance-view -g "$RESOURCE_GROUP" -n "$VM_NAME" \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv
```

### Check if apps are installed (requires RDP to VM)
```powershell
# On the VM, run:
choco list --local-only
```

### Force re-run application deployment (Terraform)
```bash
# Taint the resource to force recreation
terraform taint 'module.application_deployment.azurerm_virtual_machine_run_command.app_deployment[0]'

# Apply changes
terraform apply -var-file=terraform.tfvars.dev
```

## 📊 Health Check Script

Save this as `quick-health-check.sh`:

```bash
#!/bin/bash
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
VM_NAME=$(terraform output -json session_host_vm_names | jq -r '.[0]')
HOST_POOL=$(terraform output -raw host_pool_name)

echo "=== AVD Health Check ==="
echo ""
echo "Resource Group: $RESOURCE_GROUP"
echo "VM Name: $VM_NAME"
echo "Host Pool: $HOST_POOL"
echo ""

echo "VM Power State:"
az vm get-instance-view -g "$RESOURCE_GROUP" -n "$VM_NAME" \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv
echo ""

echo "Session Host Status:"
az desktopvirtualization sessionhost list \
  -g "$RESOURCE_GROUP" \
  --host-pool-name "$HOST_POOL" \
  --query "[].{Name:name, Status:status}" -o table
echo ""

echo "Run Command Status:"
az vm run-command show \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name avd-app-deployment \
  --query "{Name:name, State:provisioningState}" -o table 2>/dev/null || echo "Not found"
echo ""

echo "Extensions:"
az vm extension list \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --query "[].{Name:name, State:provisioningState}" -o table
```

## 🎯 Common Scenarios

### Scenario 1: "No available resources" error

```bash
# 1. Check if VM is running
az vm get-instance-view -g "$RESOURCE_GROUP" -n "$VM_NAME" \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv

# 2. Check session host registration
az desktopvirtualization sessionhost list \
  -g "$RESOURCE_GROUP" --host-pool-name "$HOST_POOL" -o table

# 3. Check application installation
./verify-installation.sh
```

### Scenario 2: Apps not installed

```bash
# Check run command output
az vm run-command show \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name avd-app-deployment \
  --instance-view \
  --query "instanceView.{State:executionState, Exit:exitCode}" -o json

# If failed, re-run deployment
terraform taint 'module.application_deployment.azurerm_virtual_machine_run_command.app_deployment[0]'
terraform apply -var-file=terraform.tfvars.dev
```

### Scenario 3: Session host not registered

```bash
# Check if AVD agent extension is installed
az vm extension show \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name "avd-hostpool-register"

# Check registration token (should not be expired)
terraform output registration_info_expiration_time
```

## 📚 Documentation Links

- Full verification guide: [VERIFICATION_GUIDE.md](VERIFICATION_GUIDE.md)
- Troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Deployment guide: [README.md](README.md)
- Deployment checklist: [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)

---

**Tip:** Add these to your `.bashrc` or `.zshrc` for quick access:
```bash
alias avd-check='./verify-installation.sh'
alias avd-rg='terraform output -raw resource_group_name'
alias avd-vm='terraform output -json session_host_vm_names | jq -r ".[0]"'
```
