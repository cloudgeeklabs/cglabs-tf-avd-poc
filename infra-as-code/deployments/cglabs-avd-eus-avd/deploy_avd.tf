terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    azuread = {
      source = "hashicorp/azuread"
    }
  }
}

provider "azurerm" {
  features {}
}


// Load up Azure Tenant Configuration
data "azurerm_client_config" "current" {}

// Variables that need to be passed in or staged
variable "resourcetags" {
  type        = map
  description = "Common Tags used for these resources"
  default = {
    Owner: "BenTheBuilder",
    Environment: "PoC",
    Notes: "AVD Lab Shared Resources"
  }
}

variable "region" {
  type        = string
  description = "Azure Region to Target"
  default     = "eastus"
}

module "avd" {
  source = "../../modules/avd"

  // AVD Settings
  prefix                            = "cglabs-avdpoc"
  resGroupName                      = "cglabs-avd-eus-avdpoc"
  region                            = var.region
  resourcetags                      = var.resourcetags
  
  // HostPool Settings
  start_vm_on_connect               = true
  personal_desktop_assignment_type  = "Direct"
  validate_environment              = false
  custom_rdp_properties             = "audiocapturemode:i:1;audiomode:i:0;"
  poolType                          = "Personal" 
  load_balancer_type                = "Persistent"

  // DAG Settings
  DAG_Type                          = "Desktop"
}
