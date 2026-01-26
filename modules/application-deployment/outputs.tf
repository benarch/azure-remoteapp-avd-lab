################################################################################
# Application Deployment Module - Outputs
################################################################################

output "extension_ids" {
  description = "List of run command IDs for all VMs"
  value       = azurerm_virtual_machine_run_command.app_deployment[*].id
}

output "deployment_status" {
  description = "Deployment status message"
  value       = "Applications deployed via Run Command. Check Azure portal for execution logs."
}
