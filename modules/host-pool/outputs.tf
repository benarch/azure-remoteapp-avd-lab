################################################################################
# Host Pool Module - Outputs
################################################################################

output "host_pool_id" {
  description = "ID of the AVD Host Pool"
  value       = azurerm_virtual_desktop_host_pool.avd.id
}

output "host_pool_name" {
  description = "Name of the AVD Host Pool"
  value       = azurerm_virtual_desktop_host_pool.avd.name
}

output "registration_info_token" {
  description = "Registration token for session hosts"
  value       = azurerm_virtual_desktop_host_pool_registration_info.avd.token
  sensitive   = true
}

output "registration_info_expiration_time" {
  description = "Expiration date of the registration token"
  value       = azurerm_virtual_desktop_host_pool_registration_info.avd.expiration_date
}
