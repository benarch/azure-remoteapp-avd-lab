#!/bin/bash

################################################################################
# Quick Start Guide - AVD Terraform Deployment
# This script provides step-by-step deployment instructions
################################################################################

cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║     Azure Virtual Desktop (AVD) Terraform Deployment - Quick Start      ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝

Project:     avd-lab1
Environment: Development / Production (Multi-workspace)
Type:        RemoteApp with Premium Applications
Region:      East US (configurable)

═══════════════════════════════════════════════════════════════════════════

📋 PREREQUISITES
═══════════════════════════════════════════════════════════════════════════

✓ Azure subscription with D-family vCPU quota
✓ Azure CLI installed and authenticated (az login)
✓ Terraform >= 1.0 installed
✓ PowerShell 5.1+ on local machine
✓ Git for version control (recommended)
✓ Local users configured (avduser1, avduser2, avduser3, avduser4)

═══════════════════════════════════════════════════════════════════════════

🚀 DEPLOYMENT IN 4 STEPS
═══════════════════════════════════════════════════════════════════════════

STEP 1: Bootstrap Storage Account (One-time, ~2 minutes)
────────────────────────────────────────────────────────

  $ cd /path/to/avd-lab1
  
  $ chmod +x bootstrap-storage.sh
  
  $ ./bootstrap-storage.sh
  
  ⚠️  IMPORTANT: Copy the output configuration and update backend.tf
  
  Example output:
    Resource Group:      rg-avd-lab1-tfstate-dev
    Storage Account:     stavdlab1XXXX
    Container Name:      tfstate

────────────────────────────────────────────────────────────────────────────

STEP 2: Initialize Terraform (~1 minute)
────────────────────────────────────────

  $ terraform init -reconfigure
  
  $ terraform workspace list
  $ terraform workspace new dev
  $ terraform workspace new prod
  
────────────────────────────────────────────────────────────────────────────

STEP 3: Configure Admin Password (Required)
──────────────────────────────────────────

  Export admin password (do NOT commit to git):
  
  $ export TF_VAR_vm_admin_password="YourSecurePassword123!"
  
  Alternative: Create terraform.tfvars.local (add to .gitignore):
  
  $ cat > terraform.tfvars.local << 'END'
  vm_admin_password = "YourSecurePassword123!"
  END
  
────────────────────────────────────────────────────────────────────────────

STEP 4: Deploy AVD Environment (~15-25 minutes)
───────────────────────────────────────────────

  # Select dev workspace
  $ terraform workspace select dev
  
  # Plan deployment
  $ terraform plan -var-file=terraform.tfvars.dev -out=tfplan
  
  # Review plan and apply
  $ terraform apply tfplan
  
  # Watch deployment progress in Azure Portal:
  # - Virtual machines: sh-dev-vm-1-dev
  # - Virtual Desktop > Host pools: hpl-avd-lab1-dev
  # - Application groups: dag-avd-lab1-*-dev
  
  # Get outputs
  $ terraform output
  
═══════════════════════════════════════════════════════════════════════════

✅ DEPLOYMENT COMPLETE
═══════════════════════════════════════════════════════════════════════════

When deployment finishes, you will have:

  ✓ Virtual Network (VNet)
    - AVD Subnet: 192.168.100.0/24
    - Bastion Subnet: 192.168.101.0/24 (reserved)
  
  ✓ Host Pool (RemoteApp)
    - Type: RemoteApp (published applications)
    - Load Balancing: Breadth-first
    - Max Sessions: 2 per host
  
  ✓ Session Hosts (VMs)
    - 1x Windows 11 multi-session VM
    - Size: Standard_D4s_v3 (4 vCPUs)
    - Auto-registered with host pool
  
  ✓ Application Groups (2)
    - Desktop Application Group
    - RemoteApp Application Group (primary)
  
  ✓ Deployed Applications
    - Microsoft Edge
    - Notepad++
    - 7Zip
    - Git + GitHub Desktop
    - Visual Studio Code
    - Visual Studio Code Insiders
  
  ✓ User Assignment
    - Users: avduser1, avduser2, avduser3, avduser4 (local users)
    - Role: Desktop Virtualization User
    - Scope: Both application groups

═══════════════════════════════════════════════════════════════════════════

🔍 VERIFY DEPLOYMENT
═══════════════════════════════════════════════════════════════════════════

  # Check session host status
  $ az vm get-instance-view \
      -g rg-avd-lab1-dev \
      -n sh-dev-vm-1-dev \
      --query "instanceView.statuses[1]"
  
  # Check extension deployment
  $ az vm extension list \
      -g rg-avd-lab1-dev \
      --vm-name sh-dev-vm-1-dev
  
  # View Terraform outputs
  $ terraform output deployment_summary
  
  # Azure Portal checks:
    1. Virtual machines: All green status
    2. Virtual Desktop > Host pools: Check host pool health
    3. Session hosts: Registered and healthy
    4. Application groups: Users assigned

═══════════════════════════════════════════════════════════════════════════

🔐 SECURITY NOTES
═══════════════════════════════════════════════════════════════════════════

  ⚠️  NEVER commit passwords to git!
      - Use environment variables: TF_VAR_vm_admin_password
      - Use local .tfvars files (add to .gitignore)
      - Consider Azure Key Vault for production

  ⚠️  NSG allows all inbound traffic
      - Recommended: Restrict to known IP ranges
      - Edit: modules/networking/main.tf
      - Update: azurerm_network_security_rule

  ⚠️  State files contain sensitive data
      - Stored encrypted in Azure Storage
      - Enable versioning (done by bootstrap)
      - Restrict access via RBAC

═══════════════════════════════════════════════════════════════════════════

📦 PRODUCTION DEPLOYMENT
═══════════════════════════════════════════════════════════════════════════

  After dev deployment succeeds, deploy prod:
  
  $ terraform workspace select prod
  $ terraform plan -var-file=terraform.tfvars.prod -out=tfplan
  $ terraform apply tfplan
  
  Note: Modify terraform.tfvars.prod for production settings:
    - Resource names with -prod suffix
    - Higher session host counts
    - Different VM sizes if needed

═══════════════════════════════════════════════════════════════════════════

🗑️  CLEANUP & DESTROY
═══════════════════════════════════════════════════════════════════════════

  To remove ALL resources:
  
  $ terraform workspace select dev
  $ terraform destroy -var-file=terraform.tfvars.dev
  
  $ terraform workspace select prod
  $ terraform destroy -var-file=terraform.tfvars.prod
  
  Note: Bootstrap storage account must be deleted manually:
  
  $ az group delete -n rg-avd-lab1-tfstate-dev -y

═══════════════════════════════════════════════════════════════════════════

📚 DOCUMENTATION
═══════════════════════════════════════════════════════════════════════════

  Full details in README.md:
  - Architecture overview
  - Configuration options
  - Troubleshooting guide
  - FAQ
  - Cost optimization tips

═══════════════════════════════════════════════════════════════════════════

❓ COMMON ISSUES & SOLUTIONS
═══════════════════════════════════════════════════════════════════════════

  Issue: "storage account name not available"
  Solution: Bootstrap script automatically generates unique name with timestamp

  Issue: "D-family quota exceeded"  
  Solution: Check quota: az vm list-usage -l eastus
           Request increase in Azure Portal > Quotas

  Issue: "User not found"
  Solution: Verify local users are configured (avduser1, avduser2, avduser3, avduser4)
           Ensure VM local accounts are properly set up

  Issue: "Extension deployment failed"
  Solution: Check logs on VM: C:\WindowsAzure\Logs\Plugins\...
           Or SSH/RDP and run: Get-Content "C:\avd-app-deploy.ps1"

═══════════════════════════════════════════════════════════════════════════

🆘 SUPPORT & RESOURCES
═══════════════════════════════════════════════════════════════════════════

  Azure Virtual Desktop Docs:
  https://docs.microsoft.com/en-us/azure/virtual-desktop/

  Terraform Azure Provider:
  https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

  AVD Terraform Examples:
  https://github.com/Azure/terraform-azurerm-deploy-avd

═══════════════════════════════════════════════════════════════════════════

Ready to deploy? Run:

  $ cd /path/to/avd-lab1
  $ ./bootstrap-storage.sh
  $ terraform init -reconfigure

═══════════════════════════════════════════════════════════════════════════

EOF
