################################################################################
# Main Orchestration File
# Orchestrates all modules for complete AVD environment deployment
# 
# Deployment Flow:
# 1. Run bootstrap-storage.sh to create Azure Storage Account for state
# 2. Update backend.tf with storage account details
# 3. Run: terraform init -reconfigure
# 4. Create workspaces: terraform workspace new dev/prod
# 5. Deploy: terraform plan -var-file=terraform.tfvars.dev
#           terraform apply -var-file=terraform.tfvars.dev
################################################################################

# Set default values and compute locals
locals {
  # Resource naming
  resource_group_name     = coalesce(var.resource_group_name, "rg-${var.resource_prefix}-${var.project_name}-${var.environment}")
  host_pool_name          = coalesce(var.host_pool_name, "hpl-${var.resource_prefix}-${var.project_name}-${var.environment}")
  workspace_name          = coalesce(var.workspace_name, "ws-${var.resource_prefix}-${var.project_name}-${var.environment}")
  desktop_app_group_name  = coalesce(var.desktop_app_group_name, "dag-${var.resource_prefix}-${var.project_name}-desktop-${var.environment}")
  remoteapp_app_group_name = coalesce(var.remoteapp_app_group_name, "dag-${var.resource_prefix}-${var.project_name}-remoteapp-${var.environment}")

  # Tags with environment
  tags = merge(
    var.common_tags,
    {
      environment = var.environment
      workspace   = terraform.workspace
      deployed_at = timestamp()
    }
  )
}

# Create Resource Group
resource "azurerm_resource_group" "avd" {
  name       = local.resource_group_name
  location   = var.location
  
  tags = local.tags
}

# Module: Networking
module "networking" {
  source = "./modules/networking"

  location                = var.location
  resource_group_name     = azurerm_resource_group.avd.name
  environment             = var.environment
  resource_prefix         = var.resource_prefix
  project_name            = var.project_name
  vnet_cidr               = var.vnet_cidr
  subnet_avd_cidr         = var.subnet_avd_cidr
  subnet_bastion_cidr     = var.subnet_bastion_cidr
  enable_public_access    = var.enable_public_access
  common_tags             = local.tags

  depends_on = [azurerm_resource_group.avd]
}

# Module: AVD Host Pool
module "host_pool" {
  source = "./modules/host-pool"

  location                     = var.location
  resource_group_name          = azurerm_resource_group.avd.name
  environment                  = var.environment
  host_pool_name               = local.host_pool_name
  host_pool_type               = var.host_pool_type
  host_pool_friendly_name      = var.host_pool_friendly_name
  host_pool_description        = var.host_pool_description
  load_balancer_type           = var.load_balancer_type
  max_session_limit            = var.max_session_limit
  start_vm_on_connect          = var.start_vm_on_connect
  rdp_properties               = var.rdp_properties
  common_tags                  = local.tags

  depends_on = [azurerm_resource_group.avd]
}

# Module: AVD Workspace
resource "azurerm_virtual_desktop_workspace" "avd" {
  name                = local.workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.avd.name
  friendly_name       = var.workspace_friendly_name
  description         = "AVD Workspace for ${var.environment} environment"

  tags = local.tags

  depends_on = [azurerm_resource_group.avd]
}

# Module: Application Groups
module "application_groups" {
  source = "./modules/application-groups"

  location                    = var.location
  resource_group_name         = azurerm_resource_group.avd.name
  environment                 = var.environment
  host_pool_id                = module.host_pool.host_pool_id
  workspace_id                = azurerm_virtual_desktop_workspace.avd.id
  desktop_app_group_name      = local.desktop_app_group_name
  remoteapp_app_group_name    = local.remoteapp_app_group_name
  common_tags                 = local.tags

  depends_on = [
    azurerm_resource_group.avd,
    module.host_pool,
    azurerm_virtual_desktop_workspace.avd
  ]
}

# Module: Session Hosts
module "session_host" {
  source = "./modules/session-host"

  location                  = var.location
  resource_group_name       = azurerm_resource_group.avd.name
  environment               = var.environment
  subnet_id                 = module.networking.subnet_avd_id
  session_host_count        = var.session_host_count
  vm_name_prefix            = var.vm_name_prefix
  vm_size                   = var.vm_size
  vm_admin_username         = var.vm_admin_username
  vm_admin_password         = var.vm_admin_password
  vm_os_disk_size_gb        = var.vm_os_disk_size_gb
  image_publisher           = var.image_publisher
  image_offer               = var.image_offer
  image_sku                 = var.image_sku
  image_version             = var.image_version
  host_pool_id              = module.host_pool.host_pool_id
  host_pool_name            = module.host_pool.host_pool_name
  registration_info_token   = module.host_pool.registration_info_token
  local_users               = var.local_users
  local_user_password       = var.local_user_password
  common_tags               = local.tags

  depends_on = [
    azurerm_resource_group.avd,
    module.networking,
    module.host_pool,
    module.application_groups
  ]
}

# Module: Application Deployment
module "application_deployment" {
  source = "./modules/application-deployment"

  location                = var.location
  resource_group_name     = azurerm_resource_group.avd.name
  environment             = var.environment
  vm_ids                  = module.session_host.session_host_vm_ids
  vm_names                = module.session_host.session_host_vm_names
  applications_to_deploy  = var.applications_to_deploy
  common_tags             = local.tags

  depends_on = [
    module.session_host
  ]
}

# Configure Per-User Access Pricing (if enabled)
resource "null_resource" "per_user_access_pricing" {
  count = var.enable_per_user_access_pricing ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'Per-user access pricing: enabled. Use Azure Portal to configure billing preferences.'"
  }

  depends_on = [azurerm_virtual_desktop_workspace.avd]
}
