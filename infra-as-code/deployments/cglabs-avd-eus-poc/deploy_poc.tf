terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.77.0"
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

module "Hosts" {
  source = "../../modules/hosts"

  // Primary Settings
  resGroupName        = "cglabs-avd-eus-poc"
  region              = var.region 
  resourcetags        = var.resourcetags
  vmPrefix            = "cglavdeuspoc" 
  numberOfHosts       = 4 

  // vNet/Subnet Configuration
  vnetName            = "cglabs-avd-eus-adds-vnet"
  subnetName          = "cglabs-avd-hostpool01"
  vnetResGroupName    = "cglabs-avd-eus-networking"

  // ACG Config
  acgImageName        = "cglabs-hostpool01"
  acgName             = "cglabsavdeusacg"
  acgResGroupName     = "cglabs-avd-eus-sharedsvcs"

  //KeyVault Config
  acgKvName           = "cglabsavdeusvlt"
  acgKvResGroupName   = "cglabs-avd-eus-sharedsvcs"

  // Host Deployment
  vmSize                = "Standard_D4s_v4"
  license_type          = "Windows_Client"
  vmAdminUserName       = "cgAdmin"
  avd_ou_path           = "OU=AVD,DC=cglabs,DC=work"
  avd_domainName        = "cglabs.work" 
  avd_hostpool_name     = "cglabs-avdpoc-hostpool"
  avd_hostpool_resgroup = "cglabs-avd-eus-avdpoc"
  avd_artifact_url      = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02384.163.zip"
}
