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
  backend "azurerm" {
    resource_group_name  = "cglabs-avd-tfstate"
    storage_account_name = "cglabsavdtfstate"
    container_name       = "cglabs-avd-poc-tfstate"
    key                  = "prod-shared-srvs.terraform.tfstate"
    subscription_id      = "197f4130-ef26-4439-a354-eb5a2a2d7f85"
    tenant_id            = "65be193c-ba88-4b25-9f1d-bd342309bea6"
    use_msi              = true
  }
}

provider "azurerm" {
  features {}
  use_msi = true
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

  // Deploy Resource Group
  resgroup                          = "cglabs-avd-poc-sharedsvcs"
  region                            = var.region
  resourcetags                      = var.resourcetags
  
  // Deploy Azure Compute Gallery
  avd-acg-umi                       = "cglabs-acg-umi"
  avd-acg-name                      = "cglabsavdeusacg"
  avd-acg-image-name                = "cglabs-hostpool01" 
  avd-acg-image-os_type             = "Windows"
  avd-acg-image-hyper_v_generation  = "V2"
  avd-acg-image-offer               = "AVD"
  avd-acg-image-publisher           = "CGLabs"
  avd-acg-image-sku                 = "poc"

  // Deploy Azure Storage Account
  avd-storageaccount-name           = "cglabsavdeusfiles"

  // Deploy LAW for AVD Diagnostic Data
  avd-law-name                      = "cglabs-avd-eus-law"
  avd-law-sku_name                  = "PerGB2018"
  avd_law-retention_in_days         = 90

  // Deploy Keyvault
  avd-kv-name                       = "cglabsavdeusvault"
  avd-kv-sku                        = "standard"  
}