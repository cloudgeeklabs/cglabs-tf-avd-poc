variable "resourcetags" {
  type        = map
  description = "Common Tags used for these resources"
}

variable "resGroupName" {
    type        = string
    description = "ResourceGroup for Deployment"
}

variable region {
    type        = string
    description = "Region that resources should be deployed"
}

variable "vmPrefix" {
    type        = string
    description = "Prefix of the name of the AVD machine(s) and Resources"
}

variable "numberOfHosts" {
    type        = number
    description = "Number of Hosts to Create and add to Pool"
}

variable "subnetName" {
  type          = string
  description   = "Target Subnet Name"
}

variable "vnetName" {
  type          = string
  description   = "Target vNet Name"
}

variable "acgName" {
  type = string
  description = "Azure Compute Gallery Name"
}

variable "acgImageName" {
  type = string
  description = "Azure Compute Gallery Image Name"
}

variable "acgResGroupName" {
  type = string
  description = "Azure Compute Gallery ResourceGroup Name"
}

variable "acgKvName" {
  type = string
  description = "Azure ACG KeyVault Name"
}

variable "acgKvResGroupName" {
  type = string
  description = "Azure ACG KeyVault ResGroup Name"
}

variable "vnetResGroupName" {
  type          = string
  description   = "ResourceGroup that contains the target vNet"
}

variable "vmSize" {
  type          = string
  description   = "(Required) The SKU which should be used for this Virtual Machine."
}

variable "license_type" {
  type          = string
  description   = "(Optional) Specifies the type of on-premise license (also known as Azure Hybrid Use Benefit) which should be used for this Virtual Machine. Possible values are None, Windows_Client and Windows_Server"
}

variable "vmAdminUserName" {
    type        = string
    description = "(Required) The username of the local administrator used for the Virtual Machine. Changing this forces a new resource to be created."
}

variable "avd_ou_path" {
  type          = string
  description   = "OU Path for AVD Hosts"
}

variable "avd_domainName" {
  type          = string
  description   = "Domain (FQDN) to join!"
}

variable "avd_artifact_url" {
  type        = string
  description = "URL to .zip file containing DSC configuration to register AVD session hosts to AVD host pool."
}

variable "avd_hostpool_name" {
  type        = string
  description = "HostPool name that hosts need to join via DSC Extension"
}

variable "avd_hostpool_resgroup" {
  type        = string
  description = "HostPool ResourceGroup Name" 
}