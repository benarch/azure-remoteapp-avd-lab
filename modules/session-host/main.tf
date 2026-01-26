################################################################################
# Session Host Module - Main Configuration
# Creates Windows 11 multi-session VMs with quota checking and registration
################################################################################

# Verify quota - this is an informational check
locals {
  vm_sku_family = regex("^Standard_D[0-9]+", var.vm_size)
  quota_vcpus_required = var.session_host_count * 4  # D4s_v3 has 4 vCPUs
  
  # In production, integrate with Azure Quota API for hard verification
  # This is a soft check that warns but doesn't block deployment
  quota_check_message = "Ensure your subscription has at least ${local.quota_vcpus_required} D-family vCPU quota in ${var.location} region"
}

# Network Interface for each VM
resource "azurerm_network_interface" "session_host" {
  count               = var.session_host_count
  name                = "${var.vm_name_prefix}nic-${count.index + 1}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name_prefix}nic-${count.index + 1}-${var.environment}"
    }
  )
}

# Windows 11 Multi-Session VM with Marketplace Plan
resource "azurerm_windows_virtual_machine" "session_host" {
  count               = var.session_host_count
  name                = "${var.vm_name_prefix}vm-${count.index + 1}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size

  admin_username = var.vm_admin_username
  admin_password = var.vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.session_host[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.vm_os_disk_size_gb
  }

  # Windows 11 Multi-session from Azure Marketplace
  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  # Note: Windows 11 images from MicrosoftWindowsDesktop don't require plan block

  # Enable boot diagnostics for troubleshooting
  boot_diagnostics {
    storage_account_uri = null  # Use managed boot diagnostics
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.vm_name_prefix}vm-${count.index + 1}-${var.environment}"
      HostPool    = var.host_pool_id
      SessionHost = "true"
    }
  )

  depends_on = [azurerm_network_interface.session_host]
}

# Register Session Host with AVD Host Pool using Custom Script Extension
# This approach uses PowerShell to download and install the AVD agents directly
resource "azurerm_virtual_machine_extension" "host_pool_registration" {
  count                      = var.session_host_count
  name                       = "avd-hostpool-register"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    "commandToExecute" = "powershell.exe -ExecutionPolicy Bypass -Command \"$ErrorActionPreference='Stop'; $AgentUrl='https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'; $BootLoaderUrl='https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'; $TempDir='C:\\Temp\\AVD'; New-Item -ItemType Directory -Force -Path $TempDir | Out-Null; Invoke-WebRequest -Uri $AgentUrl -OutFile $TempDir\\AVDAgent.msi; Invoke-WebRequest -Uri $BootLoaderUrl -OutFile $TempDir\\AVDBootLoader.msi; Start-Process msiexec.exe -ArgumentList '/i',$TempDir+'\\AVDAgent.msi','/quiet','REGISTRATIONTOKEN=${var.registration_info_token}' -Wait -NoNewWindow; Start-Process msiexec.exe -ArgumentList '/i',$TempDir+'\\AVDBootLoader.msi','/quiet' -Wait -NoNewWindow; Write-Host 'AVD Agent installation completed'\""
  })

  timeouts {
    create = "30m"
    delete = "30m"
  }

  lifecycle {
    ignore_changes = [settings]
  }
}
