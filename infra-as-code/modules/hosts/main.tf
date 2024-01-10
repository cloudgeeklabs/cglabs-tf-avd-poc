# Load up Azure Tenant Configuration
data "azurerm_client_config" "current" {}

# Pull Target vNet/Subnet info for Host NIC Configurations
data "azurerm_subnet" "poc" {
  name                 = var.subnetName
  virtual_network_name = var.vnetName
  resource_group_name  = var.vnetResGroupName
}

# Pull Target Azure Compute Gallery Image Config
data "azurerm_shared_image" "pocImage" {
  name                = var.acgImageName
  gallery_name        = var.acgName
  resource_group_name = var.acgResGroupName
}

# Pull KeyVault Config
data "azurerm_key_vault" "acgkv" {
  name                = var.acgKvName
  resource_group_name = var.acgKvResGroupName
}

data "azurerm_key_vault_secret" "acgkvadminpw" {
  name         = "avd-local-admin-password"
  key_vault_id = data.azurerm_key_vault.acgkv.id
}

data "azurerm_key_vault_secret" "adjoin-password" {
  name         = "adJoin-password"
  key_vault_id = data.azurerm_key_vault.acgkv.id
}

data "azurerm_virtual_desktop_host_pool" "hostpool" {
  name                = var.avd_hostpool_name
  resource_group_name = var.avd_hostpool_resgroup
}


# Create ResourceGroup for AVD Hosts
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "avdhostsResGroup" {
  location = var.region
  name     = var.resGroupName
  tags     = var.resourcetags 
}

# Create Host NICs
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
resource "azurerm_network_interface" "avd" {
  count               = var.numberOfHosts
  name                = "${var.vmPrefix}-${count.index}-nic"
  location            = azurerm_resource_group.avdhostsResGroup.location
  resource_group_name = azurerm_resource_group.avdhostsResGroup.name
  tags                = var.resourcetags

  ip_configuration {
    name                          = "${var.vmPrefix}-${count.index}-nic-ipconfig"
    subnet_id                     = data.azurerm_subnet.poc.id
    private_ip_address_allocation = "Dynamic"
  }
}

// Create Rotatime Time for Session Host Key
// https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating
// Must be between 1 hour and 30 days & Configured with RFC3339 Format (Azure API Requirement)
resource "time_rotating" "avd_registration_expire_token" {
  rotation_days = 5
}

// Create AVD Host Pool Registration Info
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool_registration_info
resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo" {
    hostpool_id             = data.azurerm_virtual_desktop_host_pool.hostpool.id
    expiration_date         = time_rotating.avd_registration_expire_token.rotation_rfc3339
}

# Create VMs
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine
resource "azurerm_windows_virtual_machine" "avd" {
  count                 = var.numberOfHosts
  name                  = "${var.vmPrefix}-${count.index}"
  location              = azurerm_resource_group.avdhostsResGroup.location
  resource_group_name   = azurerm_resource_group.avdhostsResGroup.name
  tags                  = var.resourcetags 

  size                  = var.vmSize
  license_type          = var.license_type
  admin_username        = var.vmAdminUserName
  admin_password        = data.azurerm_key_vault_secret.acgkvadminpw.value
  network_interface_ids = [azurerm_network_interface.avd[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  
  source_image_id = data.azurerm_shared_image.pocImage.id
}

# Join Hosts to AD Domain
resource "azurerm_virtual_machine_extension" "avd_aadds_join" {
  count                      = var.numberOfHosts
  name                       = "${var.vmPrefix}-${count.index}-adjoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "Name": "${var.avd_domainName}",
      "OUPath": "${var.avd_ou_path}",
      "User": "${var.avd_domainName}\\adJoin",
      "Restart": "true",
      "Options": "3"
    }
    SETTINGS
    protected_settings = <<-PROTECTED_SETTINGS
    {
      "Password": "${data.azurerm_key_vault_secret.adjoin-password.value}"
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}

# Register to HostPool
resource "azurerm_virtual_machine_extension" "avd_register_session_host" {
  count                = var.numberOfHosts
  name                 = "${var.vmPrefix}-${count.index}-registerhost"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd[count.index].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.73"

  settings = <<-SETTINGS
    {
      "modulesUrl": "${var.avd_artifact_url}",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "hostPoolName": "${data.azurerm_virtual_desktop_host_pool.hostpool.name}",
        "aadJoin": false
      }
    }
    SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "properties": {
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token}"
      }
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [azurerm_virtual_machine_extension.avd_aadds_join]
}


# Assign required AAD Groups Access to Desktops
