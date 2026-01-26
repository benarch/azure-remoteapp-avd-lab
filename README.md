# Azure Virtual Desktop (AVD) Terraform Deployment

Complete Terraform infrastructure-as-code for deploying an Azure Virtual Desktop environment with RemoteApp configuration, supporting multi-user deployment and multi-workspace strategy (dev/prod).

## Project Structure

```
avd-ben-lab1/
├── bootstrap-storage.sh              # Bootstrap script to create Azure Storage Account for Terraform state
├── backend.tf                        # Terraform backend configuration (Azure Storage)
├── providers.tf                      # Provider configuration (Azure/Azure AD)
├── main.tf                           # Main orchestration file
├── variables.tf                      # Variable definitions
├── terraform.tfvars                  # Shared variable defaults
├── terraform.tfvars.dev              # Dev environment overrides
├── terraform.tfvars.prod             # Prod environment overrides
├── outputs.tf                        # Output definitions
├── .gitignore                        # Git ignore patterns
└── modules/                          # Terraform modules
    ├── networking/                   # VNet, subnets, NSG
    ├── host-pool/                    # AVD host pool configuration
    ├── application-groups/           # Application groups & user assignment
    ├── session-host/                 # VMs with quota checking
    └── application-deployment/       # App installation via Custom Script Extension
```

## Prerequisites

⚠️ **IMPORTANT: Azure CLI Authentication Required**
- Azure CLI installed and authenticated: **`az login`** (REQUIRED BEFORE ANY TERRAFORM/BOOTSTRAP STEPS)
  - `az login` to authenticate to the correct Azure tenant
  - `az account show` to verify you're on the correct subscription
  - `az account list` to list all available subscriptions if needed
  - Use `az account set --subscription <SUBSCRIPTION_ID>` to switch subscriptions if necessary

- Terraform >= 1.0 installed
- PowerShell 5.1+ (on local machine for running bootstrap script)
- Azure subscription with appropriate permissions
- User to be assigned: `bendali@MngEnvMCAP990953.onmicrosoft.com` must exist in Azure AD
- D-family vCPU quota in target region (check via `az vm list-usage`)

## Architecture Overview

### Networking
- **VNet CIDR**: 192.168.100.0/22
- **Subnet 1 (AVD)**: 192.168.100.0/24 - Session hosts
- **Subnet 2 (Bastion)**: 192.168.101.0/24 - Reserved for future Bastion access
- **NSG**: Allows all inbound traffic (public access requirement)

### Host Pool Configuration
- **Type**: RemoteApp (not Desktop)
- **Load Balancing**: Breadth-first
- **Max Sessions**: 2 per host
- **Start VM on Connect**: Enabled
- **RDP Properties**:
  - Clipboard redirection: Enabled ✓
  - Drive redirection: Disabled ✗
  - Multi-display support: Enabled ✓

### Application Groups
1. **Desktop Application Group** - Standard desktop access
2. **RemoteApp Application Group** (Primary) - Published applications

### Session Hosts
- **VM Size**: Standard_D4s_v3 (D-family, 4 vCPUs)
- **OS**: Windows 11 multi-session (MicrosoftWindowsDesktop/windows-11/win11-22h2-avd)
- **Count**: 1 (configurable via `session_host_count` variable)
- **Registration**: Automatic via DSC extension

### Applications Deployed
- File Explorer
- Microsoft Edge
- Task Manager
- Notepad++
- Visual Studio Code
- Visual Studio Code Insiders
- Git
- GitHub Desktop

### User Assignment
- **User**: bendali@MngEnvMCAP990953.onmicrosoft.com
- **Role**: Desktop Virtualization User
- **Scope**: Both application groups (Desktop & RemoteApp)

## Deployment Steps

### Step 1: Bootstrap Azure Storage Container (One-time)

Run the bootstrap script to create Azure Storage Account for Terraform state:

```bash
cd /path/to/avd-ben-lab1
chmod +x bootstrap-storage.sh

# Optional: Set environment variables
export LOCATION="eastus"
export ENVIRONMENT="dev"

# Run bootstrap script
./bootstrap-storage.sh
```

The script will output:
```
Resource Group:      rg-avd-ben-lab1-tfstate-dev
Storage Account:     stavdbenlab1XXXX
Container Name:      tfstate

Backend Configuration:
  backend "azurerm" {
    resource_group_name  = "rg-avd-ben-lab1-tfstate-dev"
    storage_account_name = "stavdbenlab1XXXX"
    container_name       = "tfstate"
    key                  = "env:/${terraform.workspace}/terraform.tfstate"
  }
```

### Step 2: Update Backend Configuration

Copy the backend configuration from bootstrap output and update `backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-avd-ben-lab1-tfstate-dev"
    storage_account_name = "stavdbenlab1XXXX"
    container_account_name       = "tfstate"
    key                  = "env:/${terraform.workspace}/terraform.tfstate"
  }
}
```

### Step 3: Initialize Terraform

```bash
# Initialize with backend reconfiguration
terraform init -reconfigure

# Verify initialization
terraform workspace list
```

### Step 4: Create Workspaces

```bash
# Create dev workspace
terraform workspace new dev

# Create prod workspace
terraform workspace new prod

# List workspaces
terraform workspace list
```

### Step 5: Configure VM Admin Password

Export the admin password for session hosts (or update `terraform.tfvars`):

```bash
export TF_VAR_vm_admin_password="YourSecurePassword123!"
```

**Note**: Do NOT commit passwords to git. Use environment variables or `.tfvars.local` files (add to `.gitignore`).

### Step 6: Plan Deployment

```bash
# Select dev workspace
terraform workspace select dev

# Plan with dev variables
terraform plan -var-file=terraform.tfvars.dev -out=tfplan

# Review plan output
```

### Step 7: Apply Deployment

```bash
# Apply with dev variables
terraform apply tfplan

# Or apply directly
terraform apply -var-file=terraform.tfvars.dev -auto-approve

# Wait for deployment (typically 15-25 minutes)
```

### Step 8: Verify Deployment

```bash
# Get deployment outputs
terraform output

# Check specific outputs
terraform output host_pool_name
terraform output session_host_vm_names
terraform output assigned_user_email
```

### Production Deployment

Repeat steps 6-8 for production:

```bash
terraform workspace select prod
terraform plan -var-file=terraform.tfvars.prod
terraform apply -var-file=terraform.tfvars.prod
```

## Configuration & Customization

### Modify Core Settings

Edit `terraform.tfvars` to change shared defaults:

```hcl
# VM Size
vm_size = "Standard_D4s_v3"

# Session host count
session_host_count = 1

# Max sessions per host
max_session_limit = 2

# User email
aad_admin_user_email = "bendali@MngEnvMCAP990953.onmicrosoft.com"
```

### Environment-Specific Overrides

Edit `terraform.tfvars.dev` or `terraform.tfvars.prod`:

```hcl
# Different VM sizes per environment
session_host_count = 1  # Dev
# vs
session_host_count = 3  # Prod

# Different resource names
resource_group_name = "rg-avd-ben-lab1-dev"  # Dev
# vs
resource_group_name = "rg-avd-ben-lab1-prod" # Prod
```

### Add More Applications

Edit `terraform.tfvars` and add to `rdp_properties` or update the PowerShell deploymentScript in `modules/application-deployment/main.tf`.

### Change Network CIDR

Edit `terraform.tfvars`:

```hcl
vnet_cidr         = "192.168.100.0/22"
subnet_avd_cidr   = "192.168.100.0/24"
subnet_bastion_cidr = "192.168.101.0/24"
```

## Workspace Management

### Switching Between Workspaces

```bash
# List all workspaces
terraform workspace list

# Select workspace
terraform workspace select dev
terraform workspace select prod

# Show current workspace
terraform workspace show

# Delete workspace (must not be current)
terraform workspace delete staging
```

### State File Locations

Each workspace maintains separate state in Azure Storage:

```
Container: tfstate/
├── env:/dev/terraform.tfstate
├── env:/prod/terraform.tfstate
└── terraform.tfstate (default workspace)
```

## Monitoring & Troubleshooting

### Check Session Host Status

```bash
# List VMs
az vm list -g rg-avd-ben-lab1-dev --output table

# Check VM running status
az vm get-instance-view -g rg-avd-ben-lab1-dev -n sh-dev-vm-1-dev

# Check extension status
az vm extension list -g rg-avd-ben-lab1-dev --vm-name sh-dev-vm-1-dev
```

### View Extension Logs

On session host VM (via Bastion or RDP):

```powershell
# Custom Script Extension logs
Get-Content "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\1.10\commandExecutionLog.log"

# Application deployment script
Get-Content "C:\avd-app-deploy.ps1"
```

### Verify User Assignment

```bash
# Check role assignments
az role assignment list --scope /subscriptions/{subscriptionId}/resourceGroups/rg-avd-ben-lab1-dev

# Search for user assignment
az role assignment list --assignee bendali@MngEnvMCAP990953.onmicrosoft.com
```

### Check Host Pool Status

Azure Portal > Azure Virtual Desktop > Host pools > [host-pool-name]
- Session hosts tab: Check registration status
- Users: Verify user assignments
- Diagnostics: Review session activity

## Cleanup & Destruction

### Destroy Dev Environment

```bash
terraform workspace select dev
terraform destroy -var-file=terraform.tfvars.dev
```

### Destroy All Resources

```bash
# Destroy all workspaces
terraform workspace select dev && terraform destroy -var-file=terraform.tfvars.dev
terraform workspace select prod && terraform destroy -var-file=terraform.tfvars.prod

# Destroy storage account and bootstrap RG manually (not managed by Terraform)
az group delete -n rg-avd-ben-lab1-tfstate-dev -y
```

## Security Considerations

1. **State File Security**:
   - State files stored in Azure Storage with encryption
   - Enable Storage Account versioning (done by bootstrap script)
   - Restrict access via RBAC on storage account

2. **Admin Password**:
   - Do NOT commit passwords to git
   - Use environment variables: `TF_VAR_vm_admin_password`
   - Or use `.tfvars.local` (add to `.gitignore`)
   - Consider using Azure Key Vault for production

3. **NSG Rules**:
   - Current config allows all inbound traffic
   - For production, restrict to specific IP ranges
   - Modify `modules/networking/main.tf` for stricter rules

4. **User Assignments**:
   - Uses Azure AD integration
   - Verify user exists in AAD before deployment
   - Role assignments use principle of least privilege (Desktop Virtualization User)

5. **Marketplace Plan Acceptance**:
   - Windows 11 multi-session requires plan acceptance
   - Automated in Terraform via `plan` block
   - First deployment may require manual acceptance if plan block rejected

## Cost Optimization

- VM Size: Standard_D4s_v3 (~$165/month)
- Per-User Access Pricing: Enabled (requires Azure Subscription licensing)
- Remove/reduce session hosts in dev environment
- Use spot VMs for dev (modify `azurerm_windows_virtual_machine` for cost savings)

## FAQ

**Q: What if VM deployment fails with quota error?**
A: Check quota: `az vm list-usage -l eastus`. Request quota increase via Azure Portal > Quotas.

**Q: How do I scale to more session hosts?**
A: Update `session_host_count` in `terraform.tfvars`:
```hcl
session_host_count = 3  # Creates 3 VMs
```

**Q: How do I add more users to the application groups?**
A: Module needs enhancement to support multiple users. Currently supports single user via `aad_admin_user_email`.

**Q: Can I use a custom VM image instead of Marketplace?**
A: Yes, modify `modules/session-host/main.tf` `source_image_reference` to use custom image ID.

**Q: Why is application deployment taking so long?**
A: VS Code and Git installers download from internet. Timeout set to 30 minutes. Check logs on VM.

## Support & Documentation

- [Azure Virtual Desktop Documentation](https://docs.microsoft.com/en-us/azure/virtual-desktop/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Virtual Desktop Terraform Examples](https://github.com/Azure/terraform-azurerm-deploy-avd)

---

**Project**: AVD Ben Lab 1  
**Environment**: Development / Production  
**Last Updated**: 2026-01-26  
**Terraform Version**: >= 1.0  
**Azure Provider Version**: >= 3.50
