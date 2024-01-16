image_version       = "2024.1601.0001"
image_name          = "cglabs-win10-dedicated" 
gallery_name        = "cglabsavdeusacg"
acgResGroup         = "cglabs-avd-eus-sharedsvcs"
subscription_id     = "197f4130-ef26-4439-a354-eb5a2a2d7f85"
image_sku           = "win10-22h2-avd-m365-g2"
image_offer         = "office-365"
image_publisher     = "microsoftwindowsdesktop"
location            = "eastus"
vm_size             = "Standard_D4s_v5"
replication_regions = ["EastUS"]
azure_tags          = {
    notes = "Windows 10 with FSLogix and Office 365 ProPlus"
    owner = "BenTheBuilder"
}
