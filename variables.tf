################################################################################
# Terraform Variables
# Core variable definitions for AVD environment
# Override values in terraform.tfvars.dev and terraform.tfvars.prod
################################################################################

# Environment and General Configuration
variable "environment" {
  description = "Environment name (dev, prod, staging)"
  type        = string
  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "Environment must be dev, prod, or staging."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "resource_prefix" {
  description = "Prefix for all resource names to ensure uniqueness"
  type        = string
  default     = "avd"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "ben-lab1"
}

# Resource Group
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = ""
}

# Networking Configuration
variable "vnet_cidr" {
  description = "CIDR range for Virtual Network"
  type        = string
  default     = "192.168.100.0/22"
}

variable "subnet_avd_cidr" {
  description = "CIDR range for AVD session host subnet"
  type        = string
  default     = "192.168.100.0/24"
}

variable "subnet_bastion_cidr" {
  description = "CIDR range for Bastion subnet (reserved for future use)"
  type        = string
  default     = "192.168.101.0/24"
}

# Host Pool Configuration
variable "host_pool_name" {
  description = "Name of the AVD Host Pool"
  type        = string
  default     = ""
}

variable "host_pool_type" {
  description = "Type of host pool (Personal or Pooled). Use Pooled for RemoteApp."
  type        = string
  default     = "Pooled"
}

variable "host_pool_friendly_name" {
  description = "Friendly name for the host pool"
  type        = string
  default     = "AVD RemoteApp Host Pool"
}

variable "host_pool_description" {
  description = "Description of the host pool"
  type        = string
  default     = "AVD Host Pool for Remote Application Delivery"
}

variable "load_balancer_type" {
  description = "Load balancing algorithm type"
  type        = string
  default     = "BreadthFirst"
}

variable "max_session_limit" {
  description = "Maximum number of sessions per session host"
  type        = number
  default     = 2
}

variable "start_vm_on_connect" {
  description = "Start VM on user connection"
  type        = bool
  default     = true
}

# RDP Properties Configuration
variable "rdp_properties" {
  description = "RDP properties for session hosts. Keys should include type indicator (e.g., 'audiocapturemode:i' for integer, 'drivestoredirect:s' for string)"
  type        = map(string)
  default = {
    "audiocapturemode:i"    = "0"       # Do not record audio
    "audiomode:i"           = "0"       # Audio playback via RDP
    "camerastoredirect:s"   = "*"       # All cameras
    "redirectclipboard:i"   = "1"       # Enable clipboard
    "drivestoredirect:s"    = ""        # No drive redirection
    "redirectcomports:i"    = "0"       # Disable COM port
    "redirectlocation:i"    = "0"       # Disable location
    "redirectprinters:i"    = "0"       # Disable printers
    "redirectsmartcards:i"  = "1"       # Smart card enabled
    "redirectwebauthn:i"    = "1"       # WebAuthn enabled
    "screen mode id:i"      = "2"       # Multi-display support
    "smart sizing:i"        = "1"       # Smart sizing
    "use multimon:i"        = "1"       # Multi-monitor enabled
    "videoplaybackmode:i"   = "1"       # Optimized video
  }
}

# Application Group Configuration
variable "desktop_app_group_name" {
  description = "Name of the Desktop application group"
  type        = string
  default     = ""
}

variable "remoteapp_app_group_name" {
  description = "Name of the RemoteApp application group"
  type        = string
  default     = ""
}

# Workspace Configuration
variable "workspace_name" {
  description = "Name of the AVD Workspace"
  type        = string
  default     = ""
}

variable "workspace_friendly_name" {
  description = "Friendly name for the workspace"
  type        = string
  default     = "AVD RemoteApp Environment"
}

# Session Host Configuration
variable "session_host_count" {
  description = "Number of session hosts to create"
  type        = number
  default     = 1
}

variable "vm_name_prefix" {
  description = "Prefix for session host VM names"
  type        = string
  default     = "sh"
}

variable "vm_size" {
  description = "Azure VM size (D-family with 4 vCPUs recommended)"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "vm_admin_username" {
  description = "Admin username for session host VMs"
  type        = string
  default     = "avdadmin"
  sensitive   = true
}

variable "vm_admin_password" {
  description = "Admin password for session host VMs"
  type        = string
  sensitive   = true
}

variable "vm_os_disk_size_gb" {
  description = "Size of OS disk in GB"
  type        = number
  default     = 128
}

# Image Configuration
variable "image_publisher" {
  description = "Publisher of the VM image"
  type        = string
  default     = "MicrosoftWindowsDesktop"
}

variable "image_offer" {
  description = "Offer of the VM image"
  type        = string
  default     = "windows-11"
}

variable "image_sku" {
  description = "SKU of the VM image (Windows 11 multi-session)"
  type        = string
  default     = "win11-22h2-avd"
}

variable "image_version" {
  description = "Version of the VM image"
  type        = string
  default     = "latest"
}

# Azure AD User Assignment
variable "aad_admin_user_email" {
  description = "Email of AAD user to assign to application groups"
  type        = string
  default     = "bendali@MngEnvMCAP990953.onmicrosoft.com"
}

# Applications Configuration
variable "applications_to_deploy" {
  description = "List of applications to deploy"
  type        = list(string)
  default = [
    "File Explorer",
    "Microsoft Edge",
    "Task Manager",
    "Notepad",
    "Visual Studio Code",
    "Visual Studio Code Insiders",
    "Git Desktop",
    "Git Bash"
  ]
}

# Pricing and Per-User Access
variable "enable_per_user_access_pricing" {
  description = "Enable per-user access based pricing"
  type        = bool
  default     = true
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    "SecurityControl" = "Ignore"
    "Project"         = "cp-avd"
    "ManagedBy"       = "Terraform"
    "environment"     = "dev"
  }
}

# Public Access
variable "enable_public_access" {
  description = "Enable public access from all networks"
  type        = bool
  default     = true
}
