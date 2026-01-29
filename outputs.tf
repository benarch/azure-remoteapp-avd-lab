################################################################################
# Terraform Outputs
# Consolidated outputs from all modules and main resources
################################################################################

# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = azurerm_resource_group.avd.name
}

output "resource_group_id" {
  description = "ID of the Resource Group"
  value       = azurerm_resource_group.avd.id
}

output "location" {
  description = "Azure region of deployment"
  value       = azurerm_resource_group.avd.location
}

# Networking Outputs
output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = module.networking.vnet_name
}

output "subnet_avd_id" {
  description = "ID of the AVD subnet"
  value       = module.networking.subnet_avd_id
}

output "subnet_bastion_id" {
  description = "ID of the Bastion subnet"
  value       = module.networking.subnet_bastion_id
}

# Host Pool Outputs
output "host_pool_id" {
  description = "ID of the AVD Host Pool"
  value       = module.host_pool.host_pool_id
}

output "host_pool_name" {
  description = "Name of the AVD Host Pool"
  value       = module.host_pool.host_pool_name
}

output "registration_info_expiration_time" {
  description = "Expiration time of the registration token"
  value       = module.host_pool.registration_info_expiration_time
}

# Workspace Outputs
output "workspace_id" {
  description = "ID of the AVD Workspace"
  value       = azurerm_virtual_desktop_workspace.avd.id
}

output "workspace_name" {
  description = "Name of the AVD Workspace"
  value       = azurerm_virtual_desktop_workspace.avd.name
}

# Application Group Outputs
output "desktop_app_group_id" {
  description = "ID of the Desktop Application Group"
  value       = module.application_groups.desktop_app_group_id
}

output "desktop_app_group_name" {
  description = "Name of the Desktop Application Group"
  value       = module.application_groups.desktop_app_group_name
}

output "remoteapp_app_group_id" {
  description = "ID of the RemoteApp Application Group"
  value       = module.application_groups.remoteapp_app_group_id
}

output "remoteapp_app_group_name" {
  description = "Name of the RemoteApp Application Group"
  value       = module.application_groups.remoteapp_app_group_name
}

# Session Host Outputs
output "session_host_vm_ids" {
  description = "List of Session Host VM IDs"
  value       = module.session_host.session_host_vm_ids
}

output "session_host_vm_names" {
  description = "List of Session Host VM Names"
  value       = module.session_host.session_host_vm_names
}

output "session_host_private_ips" {
  description = "List of Session Host Private IP Addresses"
  value       = module.session_host.session_host_private_ips
}

output "quota_check_message" {
  description = "Quota verification message"
  value       = module.session_host.quota_check_message
}

# Local User Information
output "local_users" {
  description = "List of local users created on session hosts"
  value       = var.local_users
}

# Application Deployment Outputs
output "application_deployment_status" {
  description = "Status of application deployment"
  value       = module.application_deployment.deployment_status
}

output "application_deployment_verification" {
  description = "Instructions to verify application deployment"
  value       = module.application_deployment.verification_instructions
}

output "run_command_ids" {
  description = "Run command extension IDs for verification"
  value       = module.application_deployment.extension_ids
}

output "run_command_names" {
  description = "Run command names for verification"
  value       = module.application_deployment.run_command_names
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of deployed AVD environment"
  value = {
    environment             = var.environment
    workspace_name          = terraform.workspace
    location                = azurerm_resource_group.avd.location
    host_pool_type          = var.host_pool_type
    session_host_count      = var.session_host_count
    vm_size                 = var.vm_size
    load_balancer_algorithm = var.load_balancer_type
    max_session_limit       = var.max_session_limit
    per_user_access_pricing = var.enable_per_user_access_pricing
    vnet_cidr               = var.vnet_cidr
    deployment_timestamp    = timestamp()
  }
}

# Next Steps
output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    ╔════════════════════════════════════════════════════════════╗
    ║         AVD Environment Deployment Completed              ║
    ╚════════════════════════════════════════════════════════════╝
    
    1. Verify Session Hosts:
       - Check Azure Portal for running VMs
       - Verify host pool registration
    
    2. Configure Applications:
       - Applications deployed via Custom Script Extension
       - Check VM logs at C:\avd-app-deploy.ps1
    
    3. Local Users Created (for RDP access):
       - avduser1, avduser2, avduser3, avduser4
       - Password: (set via local_user_password variable)
       - All users added to "Remote Desktop Users" group
    
    4. Test User Access:
       - Connect via RDP to session host private IP
       - Or use session host VM name with local credentials
       - Format: hostname\username (e.g., sh-dev-vm-1-dev\avduser1)
    
    5. Next Deployment (if needed):
       - terraform workspace select prod
       - terraform plan -var-file=terraform.tfvars.prod
       - terraform apply -var-file=terraform.tfvars.prod
    
    6. Monitoring:
       - Monitor host pool health in Azure Portal
       - Check session activity and load balancing
       - Review performance metrics
       
    Environment Details:
    - Environment: ${var.environment}
    - Workspace: ${terraform.workspace}
    - Region: ${azurerm_resource_group.avd.location}
    - Resource Group: ${azurerm_resource_group.avd.name}
  EOT
}
