packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 1"
    }
  }
}

// Variables Section
variable "client_id" {
  type    = string
  default = "${env("ARM_CLIENT_ID")}"
}
variable "client_secret" {
  type    = string
  default = "${env("ARM_CLIENT_SECRET")}"
}
variable "tenant_id" {
  type    = string
  default = "${env("ARM_TENANT_ID")}"
}
variable "image_version" {
  type    = string
}
variable "image_name" {
  type   = string
}
variable "gallery_name" {
  type   = string
}
variable "acgResGroup" {
  type   = string
}
variable "subscription_id" {
  type   = string
}

// The Fun Bits 
// https://developer.hashicorp.com/packer/integrations/hashicorp/azure/latest/components/builder/arm
source "azure-arm" "createImage" {
  azure_tags = "${var.azure_tags}"
  client_id                         = "${var.client_id}"
  client_secret                     = "${var.client_secret}"
  communicator                      = "winrm"
  image_offer                       = "${var.image_offer}"
  image_publisher                   = "${var.image_publisher}"
  image_sku                         = "${var.image_sku}"
  location                          = "${var.location}"
  managed_image_name                = "${var.image_name}"
  managed_image_resource_group_name = "${var.acgResGroup}"
  os_type                           = "Windows"
  shared_image_gallery_destination {
    gallery_name        = "${var.gallery_name}"
    image_name          = "${var.image_name}"
    image_version       = "${var.image_version}"
    replication_regions = "${var.replication_regions}"
    resource_group      = "${var.acgResGroup}"
  }
  subscription_id = "${var.subscription_id}"
  tenant_id       = "${var.tenant_id}"
  vm_size         = "${var.vm_size}"
  winrm_insecure  = true
  winrm_timeout   = "3m"
  winrm_use_ssl   = true
  winrm_username  = "packer"
}

build {
  sources = ["source.azure-arm.createImage"]

  // Example of a Shared Config
  provisioner "file" {
    destination = "c:\\Windows\\OEM\\SetupComplete2.cmd"
    source      = "./packer-build/sharedScripts/simple_SetupComplete2.cmd"
  }

  // Example of Image Specific Script
  provisioner "powershell" {
    script = "./packer-build/hostpool01/scripts/example-software.ps1"
  }

  // Restart VM before Sysprep to make sure it is a clean caputer
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
  }

  // Inline SysPrep the image so it is ready for deployment. 
  provisioner "powershell" {
    inline = [
      "if( Test-Path $Env:SystemRoot\\windows\\system32\\Sysprep\\unattend.xml ){ rm $Env:SystemRoot\\windows\\system32\\Sysprep\\unattend.xml -Force}",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; Write-Output $imageState.ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Start-Sleep -s 10 } else { break } }",
    ]
  }
}
