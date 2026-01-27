################################################################################
# Session Host Module - Variables
################################################################################

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for VMs"
  type        = string
}

variable "session_host_count" {
  description = "Number of session hosts to create"
  type        = number
  default     = 1
}

variable "vm_name_prefix" {
  description = "Prefix for VM names"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
}

variable "vm_admin_username" {
  description = "Admin username for VMs"
  type        = string
  sensitive   = true
}

variable "vm_admin_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
}

variable "vm_os_disk_size_gb" {
  description = "Size of OS disk in GB"
  type        = number
  default     = 128
}

variable "image_publisher" {
  description = "Publisher of the VM image"
  type        = string
}

variable "image_offer" {
  description = "Offer of the VM image"
  type        = string
}

variable "image_sku" {
  description = "SKU of the VM image"
  type        = string
}

variable "image_version" {
  description = "Version of the VM image"
  type        = string
}

variable "host_pool_id" {
  description = "ID of the AVD Host Pool"
  type        = string
}

variable "host_pool_name" {
  description = "Name of the AVD Host Pool (for DSC registration)"
  type        = string
}

variable "registration_info_token" {
  description = "Registration token for host pool"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
}

variable "avd_user_principal_id" {
  description = "Principal ID of the AVD user for VM login permissions"
  type        = string
}
