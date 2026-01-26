# AVD Terraform Deployment Checklist

## Pre-Deployment Checklist

### Environment & Credentials
- [ ] Azure CLI installed: `az --version`
- [ ] Logged into Azure: `az login`
- [ ] Correct subscription selected: `az account show`
- [ ] Terraform installed: `terraform --version` (>= 1.0)
- [ ] Git installed (recommended): `git --version`

### Azure Subscription
- [ ] Have access to target Azure subscription
- [ ] User `bendali@MngEnvMCAP990953.onmicrosoft.com` exists in Azure AD
- [ ] D-family vCPU quota available in East US region
  ```bash
  az vm list-usage -l eastus --query "[?name.value=='StandardDFamily']"
  ```
- [ ] Check quota status: Target is 4 vCPUs for single D4s_v3 VM

### Project Files
- [ ] All Terraform files present in workspace directory
- [ ] `.gitignore` configured properly
- [ ] README.md and QUICKSTART.sh available

---

## Bootstrap Phase (Step 1)

### Pre-Bootstrap
- [ ] Confirm `bootstrap-storage.sh` is executable: `ls -l bootstrap-storage.sh`
- [ ] Review bootstrap script: `cat bootstrap-storage.sh`
- [ ] Set optional environment variables if needed
  ```bash
  export LOCATION="eastus"
  export ENVIRONMENT="dev"
  ```

### Run Bootstrap Script
- [ ] Execute `./bootstrap-storage.sh`
- [ ] Verify success: Check for green ✓ checkmarks in output
- [ ] Copy output information:
  - [ ] Resource Group Name: `rg-avd-ben-lab1-tfstate-*`
  - [ ] Storage Account Name: `stavdbenlab1XXXX`
  - [ ] Container Name: `tfstate`

### Post-Bootstrap
- [ ] Update `backend.tf` with storage account details
- [ ] Verify storage account created: `az storage account list --query "[*].name"`
- [ ] Verify container created: `az storage container list --account-name <storage-account-name>`

---

## Terraform Initialization (Step 2)

### Initialize Terraform
- [ ] Update backend.tf with bootstrap output values
- [ ] Run `terraform init -reconfigure`
- [ ] Verify init succeeds: `.terraform` directory created
- [ ] Check provider versions: `terraform version`

### Create Workspaces
- [ ] Create dev workspace: `terraform workspace new dev`
- [ ] Create prod workspace: `terraform workspace new prod`
- [ ] Verify workspaces: `terraform workspace list`

---

## Configuration Phase (Step 3)

### Set Admin Password
- [ ] Choose secure password (14+ chars, mixed case, numbers, symbols)
- [ ] Export password: `export TF_VAR_vm_admin_password="YourPassword123!"`
- [ ] Or create `terraform.tfvars.local` file with password
- [ ] Verify `.gitignore` includes `*.local`

### Review Variable Files
- [ ] Check `terraform.tfvars` (shared defaults)
- [ ] Check `terraform.tfvars.dev` (dev overrides)
- [ ] Check `terraform.tfvars.prod` (prod overrides)
- [ ] Verify resource names are appropriate
- [ ] Confirm VNet CIDR ranges: 192.168.100.0/22
- [ ] Confirm application list in variables

### Validate Azure AD User
- [ ] Verify user exists in Azure AD:
  ```bash
  az ad user show --id bendali@MngEnvMCAP990953.onmicrosoft.com
  ```
- [ ] Confirm correct tenant: `az account show --query tenantId`

---

## Deployment Phase (Step 4)

### Pre-Deployment Validation
- [ ] Select dev workspace: `terraform workspace select dev`
- [ ] Show current workspace: `terraform workspace show` (should be `dev`)
- [ ] Verify variables: `terraform plan -var-file=terraform.tfvars.dev -out=tfplan`
- [ ] Review plan output for:
  - [ ] Resource count looks reasonable (~15-20 resources)
  - [ ] Correct VM size: `Standard_D4s_v3`
  - [ ] Correct image: Windows 11 multi-session
  - [ ] Correct subnet CIDRs
  - [ ] Correct application group types
  - [ ] No unexpected resource deletions

### Plan Review
- [ ] Save plan to file: `-out=tfplan` done
- [ ] Review in plan: `terraform show tfplan`
- [ ] Check for errors (red lines)
- [ ] Okay to proceed if no critical changes

### Deployment
- [ ] Apply plan: `terraform apply tfplan`
- [ ] Verify starting: "Terraform will perform the following actions"
- [ ] Watch for progress messages
- [ ] Typical duration: 15-25 minutes
- [ ] Monitor in Azure Portal:
  - [ ] Resource Group created: `rg-avd-ben-lab1-dev`
  - [ ] VirtualNetwork created
  - [ ] Virtual Machines starting (sh-dev-vm-1-dev)
  - [ ] Network Interfaces created
  - [ ] Disks provisioning
  - [ ] Host Pool created (hpl-avd-ben-lab1-dev)
  - [ ] Application Groups created (dag-*)
  - [ ] Workspace created (ws-avd-ben-lab1-dev)

### Post-Deployment Validation
- [ ] Deployment completes with "Apply complete!"
- [ ] No error messages in output
- [ ] Get outputs: `terraform output`
- [ ] Verify critical outputs exist:
  - [ ] `host_pool_id`
  - [ ] `host_pool_name`
  - [ ] `session_host_vm_names`
  - [ ] `session_host_private_ips`
  - [ ] `assigned_user_email`

---

## Post-Deployment Verification (Step 5)

### Azure Portal Verification
- [ ] Navigate to Resource Group: `rg-avd-ben-lab1-dev`
- [ ] Check Virtual Machines:
  - [ ] `sh-dev-vm-1-dev` exists
  - [ ] VM status: "Running"
  - [ ] OS Disk created and attached
  - [ ] Network Interface has private IP

- [ ] Check Virtual Network:
  - [ ] VNet created: `avd-vnet-dev`
  - [ ] Subnet 1 exists: `avd-subnet-avd-dev` (192.168.100.0/24)
  - [ ] Subnet 2 exists: `avd-subnet-bastion-dev` (192.168.101.0/24)
  - [ ] NSG attached: `avd-nsg-avd-dev`

- [ ] Check Host Pool:
  - [ ] Navigate to: Virtual Desktop > Host pools
  - [ ] Host pool exists: `hpl-avd-ben-lab1-dev`
  - [ ] Type: RemoteApp
  - [ ] Session host status: check "Session hosts" tab
  - [ ] Status should show: Registered, Available, or similar

- [ ] Check Application Groups:
  - [ ] Desktop app group exists: `dag-avd-ben-lab1-desktop-dev`
  - [ ] RemoteApp app group exists: `dag-avd-ben-lab1-remoteapp-dev`
  - [ ] User assignment: Check "Assignments" tab
  - [ ] User `bendali@...` should be listed

- [ ] Check Workspace:
  - [ ] Workspace created: `ws-avd-ben-lab1-dev`
  - [ ] Associated app groups visible

### Session Host Verification
- [ ] Check VM extension status:
  ```bash
  az vm extension list -g rg-avd-ben-lab1-dev --vm-name sh-dev-vm-1-dev -o table
  ```
- [ ] Extensions should include:
  - [ ] `CustomScriptExtension` (for app deployment)
  - [ ] `DSC` (for host pool registration)

- [ ] Check application deployment logs (via Bastion or VM access):
  - [ ] Log file location: `C:\avd-app-deploy.ps1`
  - [ ] Check for installation success messages
  - [ ] Review for any failed installations

### User Assignment Verification
- [ ] Check role assignments:
  ```bash
  az role assignment list --assignee bendali@MngEnvMCAP990953.onmicrosoft.com
  ```
- [ ] Verify "Desktop Virtualization User" role assigned to app groups

### Connectivity Test (Optional)
- [ ] Install Azure Virtual Desktop client on local machine
- [ ] Try to connect to: Host pool or workspace
- [ ] Authenticate with: `bendali@MngEnvMCAP990953.onmicrosoft.com`
- [ ] Verify can see: Published applications or desktop

---

## Production Deployment (Optional)

### Prepare Production
- [ ] Review and update `terraform.tfvars.prod`
- [ ] Adjust settings for production:
  - [ ] Resource naming with `-prod` suffix
  - [ ] Consider increasing `session_host_count`
  - [ ] Adjust VM size if needed
  - [ ] Update security groups/rules

### Deploy Production
- [ ] Select prod workspace: `terraform workspace select prod`
- [ ] Verify workspace: `terraform workspace show` (should be `prod`)
- [ ] Plan: `terraform plan -var-file=terraform.tfvars.prod -out=tfplan.prod`
- [ ] Review plan carefully
- [ ] Apply: `terraform apply tfplan.prod`
- [ ] Wait for completion

### Verify Production
- [ ] Same checks as dev deployment
- [ ] Check resource group: `rg-avd-ben-lab1-prod`
- [ ] Verify resource naming and configuration

---

## Troubleshooting Checklist

If deployment fails:

### Terraform Errors
- [ ] Check error message carefully
- [ ] Common issues:
  - [ ] `Error: storage account name not available` → Run bootstrap again
  - [ ] `Error: quota exceeded` → Request quota increase
  - [ ] `Error: invalid location` → Check location variable
  - [ ] `Error: user not found` → Verify AAD user exists

### Module Errors
- [ ] Check individual module creation:
  ```bash
  terraform apply -target=module.networking
  terraform apply -target=module.host_pool
  ```
- [ ] Review module variable values
- [ ] Check module resource dependencies

### Extension/Application Deployment Issues
- [ ] SSH/RDP into VM
- [ ] Check extension logs:
  ```powershell
  Get-Content "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\1.10\commandExecutionLog.log"
  ```
- [ ] Review PowerShell deployment script output

### State & Backend Issues
- [ ] Verify backend configured: `terraform show`
- [ ] Check state file in Azure Storage:
  ```bash
  az storage blob list --account-name <storage-account> -c tfstate
  ```
- [ ] If locked, check for in-progress operations

---

## Cleanup Checklist (If Needed)

### Destroy Dev Environment
- [ ] Backup outputs: `terraform output -json > outputs-dev.json`
- [ ] Select dev workspace: `terraform workspace select dev`
- [ ] Destroy: `terraform destroy -var-file=terraform.tfvars.dev`
- [ ] Confirm: Type `yes` when prompted
- [ ] Verify deletion in Azure Portal

### Destroy Prod Environment (If Deployed)
- [ ] Select prod workspace: `terraform workspace select prod`
- [ ] Destroy: `terraform destroy -var-file=terraform.tfvars.prod`
- [ ] Confirm: Type `yes` when prompted

### Remove Bootstrap Resources
- [ ] Delete storage account RG:
  ```bash
  az group delete -n rg-avd-ben-lab1-tfstate-dev -y
  ```
- [ ] Verify deletion: `az group list --query "[*].name"`

### Clean Up Workspace
- [ ] Delete Terraform workspaces:
  ```bash
  terraform workspace delete dev
  terraform workspace delete prod
  ```
- [ ] Remove local state file: `rm -rf .terraform`
- [ ] Remove plan files: `rm *.tfplan`

---

## Documentation & Reference

- [ ] Keep README.md for reference
- [ ] Review QUICKSTART.sh for command reminders
- [ ] Save this checklist for future deployments
- [ ] Document any custom changes made
- [ ] Keep bootstrap script output for record

---

## Sign-Off

Deployment completed by: ________________  Date: ________________

Environment(s) deployed:
- [ ] Dev
- [ ] Prod

Known issues / Notes:
_________________________________________________________________

_________________________________________________________________

---

**Last Updated**: 2026-01-26  
**Project**: AVD Ben Lab 1  
**Status**: [Pending / In Progress / Complete]
