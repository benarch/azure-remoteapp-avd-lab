################################################################################
# Application Groups Module - Outputs
################################################################################

output "desktop_app_group_id" {
  description = "ID of the Desktop application group"
  value       = azurerm_virtual_desktop_application_group.desktop.id
}

output "desktop_app_group_name" {
  description = "Name of the Desktop application group"
  value       = azurerm_virtual_desktop_application_group.desktop.name
}

output "remoteapp_app_group_id" {
  description = "ID of the RemoteApp application group"
  value       = azurerm_virtual_desktop_application_group.remoteapp.id
}

output "remoteapp_app_group_name" {
  description = "Name of the RemoteApp application group"
  value       = azurerm_virtual_desktop_application_group.remoteapp.name
}
