image_version       = "2023.1024.01"
image_name          = "cglabs-hostpool01" 
gallery_name        = "cglabsavdeusacg"
acgResGroup         = "cglabs-avd-eus-sharedsvcs"
subscription_id     = "197f4130-ef26-4439-a354-eb5a2a2d7f85"
image_sku           = "win11-22h2-ent"
image_offer         = "Windows-11"
image_publisher     = "MicrosoftWindowsDesktop"
location            = "eastus"
vm_size             = "Standard_D4s_v5"
replication_regions = ["EastUS"]
azure_tags          = {
    notes = "Windows 11 BaseImage for HostPool01."
    owner = "BenTheBuilder"
}
