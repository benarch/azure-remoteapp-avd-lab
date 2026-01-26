################################################################################
# Networking Module - Outputs
################################################################################

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.avd.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.avd.name
}

output "subnet_avd_id" {
  description = "ID of the AVD subnet"
  value       = azurerm_subnet.avd.id
}

output "subnet_avd_name" {
  description = "Name of the AVD subnet"
  value       = azurerm_subnet.avd.name
}

output "subnet_bastion_id" {
  description = "ID of the Bastion subnet"
  value       = azurerm_subnet.bastion.id
}

output "subnet_bastion_name" {
  description = "Name of the Bastion subnet"
  value       = azurerm_subnet.bastion.name
}

output "nsg_id" {
  description = "ID of the Network Security Group"
  value       = azurerm_network_security_group.avd.id
}

output "nsg_name" {
  description = "Name of the Network Security Group"
  value       = azurerm_network_security_group.avd.name
}
