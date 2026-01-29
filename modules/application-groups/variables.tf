################################################################################
# Application Groups Module - Variables
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

variable "host_pool_id" {
  description = "ID of the AVD Host Pool"
  type        = string
}

variable "workspace_id" {
  description = "ID of the AVD Workspace"
  type        = string
}

variable "desktop_app_group_name" {
  description = "Name of the Desktop application group"
  type        = string
}

variable "remoteapp_app_group_name" {
  description = "Name of the RemoteApp application group"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
}
