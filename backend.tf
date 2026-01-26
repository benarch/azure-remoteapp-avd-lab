################################################################################
# Terraform Backend Configuration
# Remote state stored in Azure Storage Account with workspace-based isolation
# Each workspace (dev/prod) maintains separate state files
################################################################################

terraform {
  # NOTE: For environments with strict Azure AD policies preventing storage account access
  # Using local backend for initial deployment. To migrate to Azure Storage:
  # 1. Re-enable shared key access: az storage account update -n <name> --allow-shared-key-access true
  # 2. OR Grant current user proper RBAC roles on storage account
  # 3. Then restore this backend configuration and run: terraform init -reconfigure -migrate-state
  
  # Uncomment below to use Azure Storage backend (requires proper permissions)
  # backend "azurerm" {
  #   resource_group_name  = "rg-avd-ben-lab1-tfstate-dev"
  #   storage_account_name = "stavdbenlab1002"
  #   container_name       = "tfstate"
  #   key                  = "terraform.tfstate"
  #   use_azuread_auth     = true
  # }

  # Currently using local backend
  # Delete .terraform and terraform.tfstate to reset if needed
}
