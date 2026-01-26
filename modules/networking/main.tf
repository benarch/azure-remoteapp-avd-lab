################################################################################
# Networking Module - Main Configuration
# Creates VNet with 2 subnets, NSG for public access
################################################################################

# Virtual Network
resource "azurerm_virtual_network" "avd" {
  name                = "${var.resource_prefix}-vnet-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-vnet-${var.environment}"
    }
  )
}

# Subnet 1: AVD Session Hosts
resource "azurerm_subnet" "avd" {
  name                 = "${var.resource_prefix}-subnet-avd-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.avd.name
  address_prefixes     = [var.subnet_avd_cidr]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]
}

# Subnet 2: Bastion (reserved for future)
resource "azurerm_subnet" "bastion" {
  name                 = "${var.resource_prefix}-subnet-bastion-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.avd.name
  address_prefixes     = [var.subnet_bastion_cidr]
}

# Network Security Group for AVD Subnet
resource "azurerm_network_security_group" "avd" {
  name                = "${var.resource_prefix}-nsg-avd-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-nsg-avd-${var.environment}"
    }
  )
}

# NSG Rule: Allow all inbound traffic (public access requirement)
resource "azurerm_network_security_rule" "allow_all_inbound" {
  count                       = var.enable_public_access ? 1 : 0
  name                        = "AllowAllInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.avd.name
}

# NSG Rule: Allow all outbound traffic
resource "azurerm_network_security_rule" "allow_all_outbound" {
  name                        = "AllowAllOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.avd.name
}

# Associate NSG with AVD Subnet
resource "azurerm_subnet_network_security_group_association" "avd" {
  subnet_id                 = azurerm_subnet.avd.id
  network_security_group_id = azurerm_network_security_group.avd.id
}
