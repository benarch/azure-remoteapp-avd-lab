################################################################################
# Application Deployment Module - Variables
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

variable "vm_ids" {
  description = "List of VM IDs to deploy applications to"
  type        = list(string)
}

variable "vm_names" {
  description = "List of VM names (for logging)"
  type        = list(string)
}

variable "applications_to_deploy" {
  description = "List of applications to deploy"
  type        = list(string)
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
}
