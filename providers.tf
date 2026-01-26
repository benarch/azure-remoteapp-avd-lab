################################################################################
# Terraform Provider Configuration
################################################################################

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.50"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.30"
    }
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion            = true
      graceful_shutdown                     = true
      skip_shutdown_and_force_delete         = false
    }
  }
}

provider "azuread" {
  # Uses default Azure CLI context
}
