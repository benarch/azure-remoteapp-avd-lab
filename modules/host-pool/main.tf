################################################################################
# Host Pool Module - Main Configuration
# Creates AVD Host Pool with RemoteApp type and specified RDP properties
################################################################################

# Convert RDP properties map to string format required by AVD
# Keys should already include type indicator (e.g., "audiocapturemode:i")
locals {
  rdp_properties_string = join(";", [
    for key, value in var.rdp_properties :
    "${key}:${value}"
  ])
}

# AVD Host Pool
resource "azurerm_virtual_desktop_host_pool" "avd" {
  name                             = var.host_pool_name
  location                         = var.location
  resource_group_name              = var.resource_group_name
  type                             = var.host_pool_type
  friendly_name                    = var.host_pool_friendly_name
  description                      = var.host_pool_description
  load_balancer_type               = var.load_balancer_type
  maximum_sessions_allowed         = var.max_session_limit
  start_vm_on_connect              = var.start_vm_on_connect
  personal_desktop_assignment_type = null # Only for Personal type

  # RDP Properties
  custom_rdp_properties = local.rdp_properties_string

  # Preferred Application Group Type
  preferred_app_group_type = "RailApplications" # RemoteApp

  tags = merge(
    var.common_tags,
    {
      Name = var.host_pool_name
    }
  )
}

# Host Pool Registration Info (token)
resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd.id
  expiration_date = timeadd(timestamp(), "168h") # 7 days

  lifecycle {
    ignore_changes = [expiration_date]
  }
}
