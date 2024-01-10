variable "region" {
  type        = string
  default     = "eastus"
  description = "The Azure Region for resources"
}

variable "packerAppName" {
  type        = string
  description = "Packer App Registration Name"
}

variable "resgroup" {
  type        = string
  description = "Name of the Resource group in which to deploy shared resources."
}

variable "resourcetags" {
  type        = map
  description = "Common Tags used for these resources"
}

variable "avd-acg-name" {
  type        = string
  description = "Azure Compute Gallery leveraged by AVD"
}

variable "avd-acg-image-name" {
  type        = string
  description = "ACG Image Name"
}

variable "avd-acg-image-os_type" {
  type        = string
  description = "Azure Compute Gallery Description."
}

variable "avd-acg-image-hyper_v_generation" {
  type        = string
  default     = "V2"
  description = "The generation of HyperV that the Virtual Machine used to create the Shared Image is based on. Possible values are V1 and V2. Defaults to V2. Changing this forces a new resource to be created."
  validation {
    condition     = contains(["V1", "V2"], var.avd-acg-image-hyper_v_generation)
    error_message = "Possible values are V1 and V2."
  }
}

variable "avd-acg-image-publisher" {
  type        = string
  description = "Image Publisher Info. "
}

variable "avd-acg-image-offer" {
  type        = string
  description = "Image Offer Info."
}

variable "avd-acg-image-sku" {
  type        = string
  description = "Image Sku Info."
}

variable "avd-law-name" {
  type        = string
  description = "LAW Name"
}

variable "avd-law-sku_name" {
  type        = string
  default     = "PerGB2018"
  description = "LAW SKU"
}

variable "avd-storageaccount-name" {
  type        = string
  description = "Name of Storage Account used to hold Deployment Artifacts."
}

variable "avd_law-retention_in_days" {
  type        = number
  default     = 30
  description = "Number of days to retain logs in LAW.. "
}

variable "avd-kv-name" {
  type        = string
  description = "Name of Keyvault for AVD Image/Environment."
}

variable "avd-kv-sku" {
  type        = string
  default     = "standard"
  description = "Name of Keyvault for AVD Image/Environment."
  validation {
    condition     = contains(["standard", "premium"], var.avd-kv-sku)
    error_message = "The Keyvault Sku must be one of the following: standard, premium."
  }
}
