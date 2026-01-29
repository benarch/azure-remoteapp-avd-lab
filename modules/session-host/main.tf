################################################################################
# Session Host Module - Main Configuration
# Creates Windows 11 multi-session VMs with local user authentication
# No AD/Entra join - uses local users only
################################################################################

# Verify quota - this is an informational check
locals {
  vm_sku_family        = regex("^Standard_D[0-9]+", var.vm_size)
  quota_vcpus_required = var.session_host_count * 4 # D4s_v3 has 4 vCPUs

  # In production, integrate with Azure Quota API for hard verification
  # This is a soft check that warns but doesn't block deployment
  quota_check_message = "Ensure your subscription has at least ${local.quota_vcpus_required} D-family vCPU quota in ${var.location} region"

  # Local users to create on session hosts
  local_users = var.local_users
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
    storage_account_uri = null # Use managed boot diagnostics
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

# Create Local Users on Session Hosts
# This extension creates local user accounts for RDP/RemoteApp access
resource "azurerm_virtual_machine_extension" "create_local_users" {
  count                      = var.session_host_count
  name                       = "CreateLocalUsers"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"${local.create_users_script}\""
  })

  timeouts {
    create = "30m"
    delete = "15m"
  }

  depends_on = [azurerm_windows_virtual_machine.session_host]
}

locals {
  # PowerShell script to create local users
  create_users_script = <<-EOT
    $users = @(
      @{Name='avduser1'; Password='${var.local_user_password}'; Description='AVD Local User 1'},
      @{Name='avduser2'; Password='${var.local_user_password}'; Description='AVD Local User 2'},
      @{Name='avduser3'; Password='${var.local_user_password}'; Description='AVD Local User 3'},
      @{Name='avduser4'; Password='${var.local_user_password}'; Description='AVD Local User 4'}
    );
    foreach ($user in $users) {
      $securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force;
      if (-not (Get-LocalUser -Name $user.Name -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $user.Name -Password $securePassword -Description $user.Description -PasswordNeverExpires;
        Add-LocalGroupMember -Group 'Remote Desktop Users' -Member $user.Name -ErrorAction SilentlyContinue;
        Write-Host \"Created user: $($user.Name)\";
      } else {
        Write-Host \"User already exists: $($user.Name)\";
      }
    };
    Write-Host 'Local user creation completed.'
  EOT
}

# Register Session Host with AVD Host Pool using DSC Extension
# This is the official Microsoft-recommended approach for reliable AVD registration
# Note: aadJoin is set to false for local user authentication
resource "azurerm_virtual_machine_extension" "host_pool_registration" {
  count                      = var.session_host_count
  name                       = "Microsoft.PowerShell.DSC"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip"
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = {
      hostPoolName             = var.host_pool_name
      aadJoin                  = false
      UseAgentDownloadEndpoint = true
    }
  })

  protected_settings = jsonencode({
    properties = {
      registrationInfoToken = var.registration_info_token
    }
  })

  timeouts {
    create = "60m"
    delete = "30m"
  }

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [azurerm_virtual_machine_extension.create_local_users]
}
