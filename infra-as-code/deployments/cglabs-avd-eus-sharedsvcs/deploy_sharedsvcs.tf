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


// Deploy Resources - Here is where the work happens!
module "sharedsvc" {
  source = "../../modules/shared_svcs"

  // Deploy AAD Resources
  packerAppName                     = "cglabs-packer-app"

  // Deploy Resource Group
  resgroup                          = "cglabs-avd-eus-sharedsvcs"
  region                            = var.region
  resourcetags                      = var.resourcetags
  
  // Deploy Azure Compute Gallery
  avd-acg-name                      = "cglabsavdeusacg"
  avd-acg-image-name                = "cglabs-hostpool01" 
  avd-acg-image-os_type             = "Windows"
  avd-acg-image-hyper_v_generation  = "V2"
  avd-acg-image-offer               = "AVD"
  avd-acg-image-publisher           = "CGLabs"
  avd-acg-image-sku                 = "poc"

  // Deploy Azure Storage Account
  avd-storageaccount-name           = "cglabsavdeussa01"

  // Deploy LAW for AVD Diagnostic Data
  avd-law-name                      = "cglabs-avd-eus-law"
  avd-law-sku_name                  = "PerGB2018"
  avd_law-retention_in_days         = 90

  // Deploy Keyvault
  avd-kv-name                       = "cglabsavdeusvlt"
  avd-kv-sku                        = "standard"  
}