# Diagnosing "No Available Resources" Issue

## Your Current Issue

You mentioned:
> "there are no available resources and i cannot launch the remote app"

This typically means one of these problems:
1. ❌ Session hosts not properly registered with AVD host pool
2. ❌ Applications not installed on the VMs
3. ❌ VMs not running or not available
4. ❌ User permissions not correctly assigned

## Step-by-Step Diagnosis

### Step 1: Run the Verification Script

This is the fastest way to identify the problem:

```bash
cd /path/to/ben-avd-lab1
./verify-installation.sh
```

The script will check:
- ✅ VMs are running
- ✅ Run command completed successfully
- ✅ Applications were installed
- ✅ AVD agents are registered

**Look for these in the output:**

✓ **GOOD** - Green checkmarks and "Successful installations: 7"
✗ **BAD** - Red X marks and "Failed installations" > 0

### Step 2: Quick Manual Check

If you don't have the script or want to check manually:

```bash
# Set variables from Terraform output
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
HOST_POOL=$(terraform output -raw host_pool_name)
VM_NAME=$(terraform output -json session_host_vm_names | jq -r '.[0]')

echo "Resource Group: $RESOURCE_GROUP"
echo "Host Pool: $HOST_POOL"
echo "VM Name: $VM_NAME"
```

#### 2a. Check if VM is running

```bash
az vm get-instance-view -g "$RESOURCE_GROUP" -n "$VM_NAME" \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv
```

**Expected:** `VM running`

**If not running:**
```bash
az vm start -g "$RESOURCE_GROUP" -n "$VM_NAME"
```

#### 2b. Check session host status

```bash
az desktopvirtualization sessionhost list \
  -g "$RESOURCE_GROUP" \
  --host-pool-name "$HOST_POOL" \
  --query "[].{Name:name, Status:status, LastHeartBeat:lastHeartBeat}" -o table
```

**Expected:** Status = `Available`

**Common issues:**
- Status = `Unavailable` → AVD agent not installed or not running
- Status = `NeedsAssistance` → Check VM and agent logs
- No session hosts listed → Session host never registered

#### 2c. Check application deployment

```bash
az vm run-command show \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name avd-app-deployment \
  --instance-view \
  --query "{ExecutionState:instanceView.executionState, ExitCode:instanceView.exitCode, Output:instanceView.output}" -o json
```

**Expected:** 
- ExecutionState = `Succeeded`
- ExitCode = `0`
- Output contains "Successful installations: 7"

**If failed:**
Look at the error in the output field.

### Step 3: Check User Permissions

```bash
USER_EMAIL=$(terraform output -raw assigned_user_email)

az role assignment list \
  --assignee "$USER_EMAIL" \
  --query "[?roleDefinitionName=='Desktop Virtualization User'].{Role:roleDefinitionName, Scope:scope}" -o table
```

**Expected:** At least 2 role assignments (one for Desktop app group, one for RemoteApp group)

## Common Resolutions

### Resolution 1: Applications Not Installed

If the run command shows installation failed:

**Option A: Quick manual fix (RDP to VM)**

1. Get VM admin credentials from your Terraform variables
2. RDP to the VM using Azure Portal or Bastion
3. Run PowerShell as Administrator:

```powershell
# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
# Download and execute installer (safer than Invoke-Expression)
Invoke-RestMethod 'https://community.chocolatey.org/install.ps1' -OutFile "$env:TEMP\install-choco.ps1"
& "$env:TEMP\install-choco.ps1"

# Install applications
choco install microsoft-edge notepadplusplus 7zip git github-desktop vscode vscode-insiders -y

# Verify
choco list --local-only
```

**Option B: Re-run Terraform deployment**

```bash
# Force Terraform to recreate the run command
terraform taint 'module.application_deployment.azurerm_virtual_machine_run_command.app_deployment[0]'

# Apply (will re-run the installation script)
terraform apply -var-file=terraform.tfvars.dev
```

### Resolution 2: Session Host Not Registered

If session host status is not "Available":

**Check AVD agent:**

```bash
az vm extension show \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --name "avd-hostpool-register" \
  --query "{Name:name, State:provisioningState, Status:instanceView.statuses[0].message}" -o json
```

If extension failed or doesn't exist, you may need to:

1. Check if registration token is expired:
   ```bash
   terraform output registration_info_expiration_time
   ```

2. If expired, regenerate token and re-register:
   ```bash
   terraform apply -var-file=terraform.tfvars.dev -replace="module.host_pool.azurerm_virtual_desktop_host_pool_registration_info.registration"
   ```

3. Or manually install AVD agent on the VM (via RDP):
   ```powershell
   # Download agents
   $AgentUrl = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
   $BootLoaderUrl = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH"
   
   Invoke-WebRequest -Uri $AgentUrl -OutFile "C:\Temp\AVDAgent.msi"
   Invoke-WebRequest -Uri $BootLoaderUrl -OutFile "C:\Temp\AVDBootLoader.msi"
   
   # Get token from Terraform output (run this on your local machine)
   # terraform output -raw host_pool_registration_token
   
   # Install (replace <TOKEN> with actual token)
   $Token = "<TOKEN>"
   Start-Process msiexec.exe -ArgumentList "/i C:\Temp\AVDAgent.msi /quiet REGISTRATIONTOKEN=$Token" -Wait
   Start-Process msiexec.exe -ArgumentList "/i C:\Temp\AVDBootLoader.msi /quiet" -Wait
   
   # Restart services
   Restart-Service RDAgentBootLoader
   Restart-Service RDAgent
   ```

### Resolution 3: VM Not Running

```bash
# Start the VM
az vm start -g "$RESOURCE_GROUP" -n "$VM_NAME"

# Wait for it to fully start
sleep 60

# Verify
az vm get-instance-view -g "$RESOURCE_GROUP" -n "$VM_NAME" \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv
```

## Verification After Fix

After applying any fix, wait 5-10 minutes and then:

1. **Re-run verification:**
   ```bash
   ./verify-installation.sh
   ```

2. **Check session host status:**
   ```bash
   az desktopvirtualization sessionhost list \
     -g "$RESOURCE_GROUP" \
     --host-pool-name "$HOST_POOL" -o table
   ```

3. **Try connecting to AVD:**
   - Open Azure Virtual Desktop client
   - Login with: `bendali@MngEnvMCAP990953.onmicrosoft.com`
   - Try launching a RemoteApp

## Still Having Issues?

If the problem persists:

1. **Check full installation log on VM** (via RDP):
   ```powershell
   Get-ChildItem C:\AVD-Deployment-Logs\
   Get-Content C:\AVD-Deployment-Logs\app-deployment-*.log
   ```

2. **Check AVD diagnostics in Azure Portal:**
   - Azure Portal → Azure Virtual Desktop → Host pools → [your-host-pool]
   - Click "Diagnostics" tab
   - Look for errors

3. **Check Azure Service Health:**
   - Azure Portal → Service Health
   - Look for AVD service incidents

4. **Review detailed troubleshooting guide:**
   - See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

5. **Collect information for support:**
   ```bash
   # Save verification output
   ./verify-installation.sh > verification-results.txt 2>&1
   
   # Save Terraform outputs
   terraform output -json > terraform-outputs.json
   
   # Save VM info
   az vm show -g "$RESOURCE_GROUP" -n "$VM_NAME" > vm-info.json
   ```

## Expected Timeline

- Application installation: 10-20 minutes
- Session host registration: 5-10 minutes
- Total from deployment to ready: ~20-30 minutes

If your deployment finished recently, wait a bit longer and check again.

---

**Need immediate help?**

1. Run: `./verify-installation.sh` and share the output
2. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions
3. Open an issue with the verification results
