################################################################################
# Host Pool Module - Variables
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

variable "host_pool_name" {
  description = "Name of the AVD Host Pool"
  type        = string
}

variable "host_pool_type" {
  description = "Type of host pool (RemoteApp or Personal)"
  type        = string
  default     = "RemoteApp"
}

variable "host_pool_friendly_name" {
  description = "Friendly name for the host pool"
  type        = string
}

variable "host_pool_description" {
  description = "Description of the host pool"
  type        = string
}

variable "load_balancer_type" {
  description = "Load balancing algorithm type"
  type        = string
}

variable "max_session_limit" {
  description = "Maximum number of sessions per session host"
  type        = number
}

variable "start_vm_on_connect" {
  description = "Start VM on user connection"
  type        = bool
}

variable "rdp_properties" {
  description = "RDP properties for sessions"
  type        = map(string)
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
}
