################################################################################
# Application Deployment Module - Outputs
################################################################################

output "extension_ids" {
  description = "List of run command IDs for all VMs"
  value       = azurerm_virtual_machine_run_command.app_deployment[*].id
}

output "run_command_names" {
  description = "List of run command names for verification"
  value       = azurerm_virtual_machine_run_command.app_deployment[*].name
}

output "vm_ids_with_deployment" {
  description = "List of VM IDs where applications were deployed"
  value       = var.vm_ids
}

output "vm_names_with_deployment" {
  description = "List of VM names where applications were deployed"
  value       = var.vm_names
}

output "deployment_status" {
  description = "Deployment status message"
  value       = "Applications deployed via Run Command. Check Azure portal for execution logs."
}

output "verification_instructions" {
  description = "Instructions to verify the installation"
  value = <<-EOT
    To verify application installation succeeded on VMs:
    
    1. Check run command status in Azure Portal:
       Azure Portal > Virtual Machines > [VM Name] > Run Command > Recent commands
    
    2. Use Azure CLI to check run command execution:
       az vm run-command show --resource-group ${var.resource_group_name} --name [VM_NAME] --run-command-name avd-app-deployment
    
    3. View run command output logs:
       az vm run-command show --resource-group ${var.resource_group_name} --name [VM_NAME] --run-command-name avd-app-deployment --instance-view
    
    4. RDP to VM and verify applications installed:
       - Check: C:\ProgramData\chocolatey\bin\choco.exe exists
       - Run: choco list --local-only
       - Verify apps in Start Menu: Edge, Notepad++, 7Zip, Git, VS Code
  EOT
}
