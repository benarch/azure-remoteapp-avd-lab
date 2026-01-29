################################################################################
# Terraform Provider Configuration
# Note: No Azure AD/Entra provider - using local user authentication only
################################################################################

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.50"
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
