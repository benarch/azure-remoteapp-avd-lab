################################################################################
# Networking Module - Variables
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

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR range for Virtual Network"
  type        = string
}

variable "subnet_avd_cidr" {
  description = "CIDR range for AVD subnet"
  type        = string
}

variable "subnet_bastion_cidr" {
  description = "CIDR range for Bastion subnet"
  type        = string
}

variable "enable_public_access" {
  description = "Enable public access from all networks"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
}
