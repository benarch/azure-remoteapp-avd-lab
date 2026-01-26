# AVD Troubleshooting Guide

## Common Issues and Solutions

### Issue: "No Available Resources" Error

**Symptoms:**
- Cannot launch remote applications
- Error message: "There are no available resources"
- Applications show in workspace but won't launch

**Root Causes:**
1. Session hosts not properly registered with host pool
2. Applications not installed on session hosts
3. Session host VMs not running
4. User permissions not properly assigned
5. Max session limit reached

**Solution Steps:**

#### 1. Verify Session Host Registration

```bash
# Check session host status
az desktopvirtualization sessionhost list \
  --resource-group <resource-group-name> \
  --host-pool-name <host-pool-name> \
  --query "[].{Name:name, Status:status, UpdateState:updateState}" -o table
```

Expected status: `Available`

If status is not `Available`:
- Check if VM is running
- Verify AVD agent is installed
- Check agent registration logs on VM

#### 2. Verify Application Installation

```bash
# Run automated verification
./verify-installation.sh
```

The script will show:
- ✓ if applications installed successfully
- ✗ if installation failed
- Detailed logs and error messages

**If installation failed:**

Option A: Manually fix on VM (quick fix)
```bash
# RDP to the VM
# Open PowerShell as Administrator
# Run:
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
# Download and execute installer (safer than Invoke-Expression)
Invoke-RestMethod 'https://community.chocolatey.org/install.ps1' -OutFile "$env:TEMP\install-choco.ps1"
& "$env:TEMP\install-choco.ps1"

# Install apps
choco install microsoft-edge notepadplusplus 7zip git github-desktop vscode vscode-insiders -y
```

Option B: Redeploy run command (Terraform)
```bash
# Force recreation of run command
terraform taint module.application_deployment.azurerm_virtual_machine_run_command.app_deployment[0]
terraform apply -var-file=terraform.tfvars.dev
```

#### 3. Check VM Status

```bash
# List all VMs
az vm list -g <resource-group-name> --query "[].{Name:name, PowerState:powerState}" -o table

# Get detailed VM status
az vm get-instance-view \
  --resource-group <resource-group-name> \
  --name <vm-name> \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv
```

Expected: `VM running`

If VM is not running:
```bash
# Start the VM
az vm start --resource-group <resource-group-name> --name <vm-name>
```

#### 4. Verify User Permissions

```bash
# Check user role assignments
az role assignment list \
  --assignee <user-email> \
  --query "[?roleDefinitionName=='Desktop Virtualization User'].{Role:roleDefinitionName, Scope:scope}" -o table
```

User should have "Desktop Virtualization User" role on both application groups.

If missing:
```bash
# This should be handled by Terraform, but you can manually add:
az role assignment create \
  --assignee <user-email> \
  --role "Desktop Virtualization User" \
  --scope <app-group-id>
```

#### 5. Check Host Pool Capacity

```bash
# Get host pool session limit
terraform output -json deployment_summary | jq .max_session_limit

# Check active sessions
az desktopvirtualization sessionhost list \
  --resource-group <resource-group-name> \
  --host-pool-name <host-pool-name> \
  --query "[].{Name:name, Sessions:sessions}" -o table
```

If max sessions reached:
- Increase `max_session_limit` in terraform.tfvars
- Or add more session hosts by increasing `session_host_count`
- Or disconnect idle sessions

---

### Issue: Run Command Fails or Times Out

**Symptoms:**
- Application deployment shows "Failed" status
- Run command times out after 60 minutes
- Partial application installation

**Solutions:**

#### Check Run Command Status

```bash
az vm run-command show \
  --resource-group <resource-group-name> \
  --vm-name <vm-name> \
  --name avd-app-deployment \
  --instance-view
```

#### View Full Output

```bash
az vm run-command show \
  --resource-group <resource-group-name> \
  --vm-name <vm-name> \
  --name avd-app-deployment \
  --instance-view \
  --query "instanceView.output" -o tsv
```

#### Check Logs on VM

RDP to VM and check:
- `C:\AVD-Deployment-Logs\app-deployment-*.log` - Detailed installation log
- `C:\ProgramData\chocolatey\logs\chocolatey.log` - Chocolatey log

#### Common Causes:

1. **Network connectivity issues:**
   - Check if VM can reach internet
   - Verify DNS resolution
   - Test: `ping chocolatey.org` from VM

2. **Insufficient disk space:**
   - Check disk space: `Get-PSDrive C`
   - Clean up if needed

3. **TLS/SSL issues:**
   - Ensure TLS 1.2 is enabled
   - Check certificate trust

---

### Issue: AVD Agent Not Registered

**Symptoms:**
- Session host shows as "Not Registered" or "Unavailable"
- Cannot connect to session host

**Solutions:**

#### 1. Check Agent Extension Status

```bash
az vm extension list \
  --resource-group <resource-group-name> \
  --vm-name <vm-name> \
  --query "[?contains(name, 'avd') || contains(name, 'hostpool')].{Name:name, State:provisioningState, StatusMessage:instanceView.statuses[0].message}" -o table
```

#### 2. Check Registration Token

```bash
# Get token expiration
terraform output registration_info_expiration_time
```

If token expired:
```bash
# Regenerate registration token (requires Terraform reapply)
terraform apply -var-file=terraform.tfvars.dev -replace="module.host_pool.azurerm_virtual_desktop_host_pool_registration_info.registration"
```

#### 3. Manually Register Session Host

On the VM:
```powershell
# Check if agent is installed
Get-Service RDAgentBootLoader
Get-Service RDAgent

# If not installed, download and install manually
$AgentUrl = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
$BootLoaderUrl = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH"

Invoke-WebRequest -Uri $AgentUrl -OutFile "C:\Temp\AVDAgent.msi"
Invoke-WebRequest -Uri $BootLoaderUrl -OutFile "C:\Temp\AVDBootLoader.msi"

# Install with registration token (get from Terraform output)
$Token = "<registration-token>"
Start-Process msiexec.exe -ArgumentList "/i C:\Temp\AVDAgent.msi /quiet REGISTRATIONTOKEN=$Token" -Wait
Start-Process msiexec.exe -ArgumentList "/i C:\Temp\AVDBootLoader.msi /quiet" -Wait
```

---

### Issue: Chocolatey Installation Fails

**Symptoms:**
- Error: "Cannot install Chocolatey"
- Applications not installed

**Solutions:**

#### 1. Manual Chocolatey Installation

RDP to VM and run as Administrator:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
# Download and execute installer (safer than Invoke-Expression)
Invoke-RestMethod 'https://community.chocolatey.org/install.ps1' -OutFile "$env:TEMP\install-choco.ps1"
& "$env:TEMP\install-choco.ps1"
```

#### 2. Verify Installation

```powershell
choco --version
choco list --local-only
```

#### 3. Alternative: Install Apps Manually

If Chocolatey won't install, download and install apps directly:
- Microsoft Edge: Pre-installed on Windows 11
- Notepad++: https://notepad-plus-plus.org/downloads/
- 7-Zip: https://www.7-zip.org/
- Git: https://git-scm.com/downloads
- VS Code: https://code.visualstudio.com/

---

### Issue: Terraform State Issues

**Symptoms:**
- "State lock" errors
- "Resource already exists" errors
- Inconsistent state

**Solutions:**

#### 1. Check State Lock

```bash
# View state lock info in Azure Storage
az storage blob show \
  --account-name <storage-account-name> \
  --container-name tfstate \
  --name env:/<workspace>/terraform.tfstate \
  --query "metadata"
```

#### 2. Force Unlock (if stuck)

```bash
terraform force-unlock <lock-id>
```

#### 3. Refresh State

```bash
terraform refresh -var-file=terraform.tfvars.dev
```

#### 4. Import Existing Resources

If resources exist but not in state:
```bash
terraform import module.networking.azurerm_virtual_network.avd /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Network/virtualNetworks/<vnet-name>
```

---

## Diagnostic Commands Reference

### Quick Health Check

```bash
# Resource group exists
az group show -n <resource-group-name>

# VMs running
az vm list -g <resource-group-name> --show-details --query "[].{Name:name, PowerState:powerState}" -o table

# Host pool exists
az desktopvirtualization hostpool show -g <resource-group-name> -n <host-pool-name>

# Session hosts registered
az desktopvirtualization sessionhost list -g <resource-group-name> --host-pool-name <host-pool-name> -o table

# User assignments
az role assignment list --scope <app-group-id>
```

### View All Extensions on VM

```bash
az vm extension list -g <resource-group-name> --vm-name <vm-name> -o table
```

### Get Run Command Details

```bash
# List all run commands
az vm run-command list -g <resource-group-name> --vm-name <vm-name> -o table

# Show specific run command
az vm run-command show -g <resource-group-name> --vm-name <vm-name> --name avd-app-deployment --instance-view
```

---

## Escalation Path

If issues persist after trying these solutions:

1. **Check Azure Service Health:**
   - Azure Portal > Service Health
   - Look for AVD service incidents

2. **Review Azure Monitor Logs:**
   - Azure Portal > Log Analytics workspace
   - Query AVD logs

3. **Contact Support:**
   - Create support ticket in Azure Portal
   - Attach:
     - Terraform outputs
     - Verification script results
     - VM extension logs
     - Run command outputs

4. **Community Resources:**
   - Azure Virtual Desktop Tech Community
   - Stack Overflow (tag: azure-virtual-desktop)
   - GitHub Issues (for this repo)

---

**Last Updated:** 2026-01-26
