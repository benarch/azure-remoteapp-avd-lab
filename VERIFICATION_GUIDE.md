# Installation Verification - Usage Guide

## Overview

This guide shows you how to verify that your AVD deployment is working correctly, especially when you encounter issues like "no available resources" when trying to launch remote apps.

## Quick Start

After deploying your AVD environment with Terraform, run the verification script:

```bash
./verify-installation.sh
```

## What the Script Checks

The verification script performs these checks automatically:

1. ✅ **Azure CLI Authentication** - Verifies you're logged in
2. ✅ **Terraform State** - Reads deployment information
3. ✅ **VM Status** - Checks if VMs are running
4. ✅ **Run Command Status** - Verifies application deployment completed
5. ✅ **Installation Logs** - Shows output from installation script
6. ✅ **AVD Agent** - Confirms AVD host pool registration extensions

## Sample Output

### Successful Installation

```
╔════════════════════════════════════════════════════════════╗
║    AVD Installation Verification Script                   ║
╚════════════════════════════════════════════════════════════╝

✓ Azure CLI is installed and authenticated
✓ Resource Group: rg-avd-ben-lab1-dev
✓ Found VMs to verify

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Checking VM: sh-dev-vm-1-dev
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Checking VM status...
✓ VM is running
Checking application deployment run command...
  Provisioning State: Succeeded
Fetching run command output...
  Execution State: Succeeded
  Exit Code: 0
✓ Application deployment completed successfully

Last lines of output:
  ========================================
  Deployment Summary
  ========================================
  Successful installations: 7
  Failed installations: 0
  ✓ Application deployment completed successfully!

Checking AVD agent installation...
  ✓ avd-hostpool-register: Succeeded

╔════════════════════════════════════════════════════════════╗
║                    Verification Summary                   ║
╚════════════════════════════════════════════════════════════╝

Total VMs checked: 1
Successful deployments: 1
Failed deployments: 0

✓ All application deployments completed successfully!

Next steps:
  1. Connect to AVD workspace using Azure Virtual Desktop client
  2. Login with assigned user credentials
  3. Launch remote applications from the workspace
```

### Failed Installation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Checking VM: sh-dev-vm-1-dev
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Checking VM status...
✓ VM is running
Checking application deployment run command...
  Provisioning State: Succeeded
Fetching run command output...
  Execution State: Failed
  Exit Code: 1
✗ Application deployment failed or is still running
  Message: Command execution failed

Error output:
  Chocolatey installation failed: Unable to connect to remote server
  Network connectivity issue detected

╔════════════════════════════════════════════════════════════╗
║                    Verification Summary                   ║
╚════════════════════════════════════════════════════════════╝

Total VMs checked: 1
Successful deployments: 0
Failed deployments: 1

✗ Some deployments failed or are incomplete

Troubleshooting steps:
  1. RDP to the VM to check manually
  2. Check VM boot diagnostics in Azure Portal
  3. Review full run command output in Azure Portal
  4. Re-run the deployment if needed
```

## Manual Verification Commands

If the script doesn't work or you want to check specific details:

### Check Terraform Outputs

```bash
# View all outputs
terraform output

# View verification instructions
terraform output application_deployment_verification

# View run command IDs
terraform output run_command_ids
```

### Check Run Command via Azure CLI

```bash
# Replace <resource-group-name> and <vm-name> with your values
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
VM_NAME=$(terraform output -json session_host_vm_names | jq -r '.[0]')

# Check run command status
az vm run-command show \
  --resource-group "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name avd-app-deployment

# Get detailed output with instance view
az vm run-command show \
  --resource-group "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name avd-app-deployment \
  --instance-view

# Extract just the output
az vm run-command show \
  --resource-group "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name avd-app-deployment \
  --instance-view \
  --query "instanceView.output" -o tsv
```

### Check VM Status

```bash
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# List all VMs with status
az vm list -g "$RESOURCE_GROUP" --show-details \
  --query "[].{Name:name, PowerState:powerState, ProvisioningState:provisioningState}" -o table

# Check specific VM
VM_NAME=$(terraform output -json session_host_vm_names | jq -r '.[0]')
az vm get-instance-view -g "$RESOURCE_GROUP" -n "$VM_NAME"
```

### Check Session Host Registration

```bash
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
HOST_POOL=$(terraform output -raw host_pool_name)

# List session hosts
az desktopvirtualization sessionhost list \
  --resource-group "$RESOURCE_GROUP" \
  --host-pool-name "$HOST_POOL" \
  --query "[].{Name:name, Status:status}" -o table
```

## Troubleshooting Common Issues

### Issue: "No available resources" when launching apps

**Immediate Checks:**

1. Run verification script:
   ```bash
   ./verify-installation.sh
   ```

2. Check session host status:
   ```bash
   RESOURCE_GROUP=$(terraform output -raw resource_group_name)
   HOST_POOL=$(terraform output -raw host_pool_name)
   
   az desktopvirtualization sessionhost list \
     -g "$RESOURCE_GROUP" \
     --host-pool-name "$HOST_POOL" \
     -o table
   ```
   
   Expected: Status should be "Available"

3. Check if VM is running:
   ```bash
   RESOURCE_GROUP=$(terraform output -raw resource_group_name)
   
   az vm list -g "$RESOURCE_GROUP" --show-details \
     --query "[].{Name:name, PowerState:powerState}" -o table
   ```
   
   Expected: PowerState should be "VM running"

4. Verify applications installed:
   - Look at verification script output
   - Check for "Successful installations: 7" or similar
   - If failed, see recovery steps below

**Recovery Steps:**

If applications failed to install:

```bash
# Option 1: Force re-run of application deployment (Terraform)
terraform taint 'module.application_deployment.azurerm_virtual_machine_run_command.app_deployment[0]'
terraform apply -var-file=terraform.tfvars.dev

# Option 2: Manual fix via RDP
# RDP to the VM, then run PowerShell as Administrator:
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
# Download and execute Chocolatey installer (safer than Invoke-Expression)
Invoke-RestMethod 'https://community.chocolatey.org/install.ps1' -OutFile "$env:TEMP\install-choco.ps1"
& "$env:TEMP\install-choco.ps1"
choco install microsoft-edge notepadplusplus 7zip git github-desktop vscode vscode-insiders -y
```

### Issue: Run command still running

If the run command shows "Running" state:

```bash
# Wait for it to complete (max 60 minutes)
# Check status periodically:
az vm run-command show \
  --resource-group "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name avd-app-deployment \
  --query "provisioningState" -o tsv
```

### Issue: Cannot find run command

If the script reports run command not found:

```bash
# List all run commands on VM
az vm run-command list \
  --resource-group "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" -o table

# If truly missing, the Terraform deployment may have failed
# Check Terraform state:
terraform state list | grep run_command
```

## Viewing Installation Logs on the VM

If you have RDP/Bastion access to the VM:

1. **Connect to VM** via RDP or Azure Bastion

2. **Check installation log files:**
   ```powershell
   # Main deployment log (created by enhanced script)
   Get-ChildItem C:\AVD-Deployment-Logs\
   Get-Content C:\AVD-Deployment-Logs\app-deployment-*.log
   
   # Chocolatey logs
   Get-Content C:\ProgramData\chocolatey\logs\chocolatey.log
   ```

3. **Verify installed applications:**
   ```powershell
   # List Chocolatey packages
   choco list --local-only
   
   # Check if Chocolatey is installed
   Test-Path C:\ProgramData\chocolatey\bin\choco.exe
   
   # Check specific applications
   Test-Path "C:\Program Files\Notepad++\notepad++.exe"
   Test-Path "C:\Program Files\Microsoft VS Code\Code.exe"
   ```

4. **Check AVD agent status:**
   ```powershell
   Get-Service RDAgent
   Get-Service RDAgentBootLoader
   ```

## Additional Resources

- **Comprehensive Troubleshooting:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Deployment Guide:** See [README.md](README.md)
- **Deployment Checklist:** See [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)

## Getting Help

If issues persist:

1. Review the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide
2. Check Azure Service Health for AVD incidents
3. Review Azure Monitor logs in Azure Portal
4. Open an issue in this repository with:
   - Output from `./verify-installation.sh`
   - Relevant Terraform outputs
   - Error messages from Azure Portal

---

**Last Updated:** 2026-01-26
