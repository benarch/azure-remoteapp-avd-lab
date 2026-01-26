################################################################################
# Session Host Module - Outputs
################################################################################

output "session_host_vm_ids" {
  description = "List of VM IDs for all session hosts"
  value       = azurerm_windows_virtual_machine.session_host[*].id
}

output "session_host_vm_names" {
  description = "List of VM names for all session hosts"
  value       = azurerm_windows_virtual_machine.session_host[*].name
}

output "session_host_nic_ids" {
  description = "List of Network Interface IDs"
  value       = azurerm_network_interface.session_host[*].id
}

output "session_host_private_ips" {
  description = "List of private IP addresses"
  value       = azurerm_network_interface.session_host[*].private_ip_address
}

output "quota_check_message" {
  description = "Quota verification message"
  value       = local.quota_check_message
}
