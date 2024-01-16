# Load up Azure Tenant Configuration
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "subscription" {}
data "azurerm_resource_group" "vnetrg" {
  name = "cglabs-avd-eus-networking"
}

# Create ResourceGroup for AVD Shared Resources
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "avdsharedresources" {
  location = var.region
  name     = var.resgroup
  tags     = var.resourcetags 
}

# Create User Managed Identity for Accessing KeyVault and other Resources
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity
resource "azurerm_user_assigned_identity" "acg-umi" {
  name                = var.avd-acg-umi
  resource_group_name = azurerm_resource_group.avdsharedresources.name
  location            = azurerm_resource_group.avdsharedresources.location
  tags                = var.resourcetags

}

# Creates Shared Image Gallery
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/shared_image_gallery
resource "azurerm_shared_image_gallery" "acg" {
  name                = var.avd-acg-name
  resource_group_name = azurerm_resource_group.avdsharedresources.name
  location            = azurerm_resource_group.avdsharedresources.location
  description         = var.avd-acg-name
  tags                = var.resourcetags
}

# Set RBAC Permissions on Compute Image Gallery
resource "azurerm_role_assignment" "acg-role-assignment" {
  scope                 = azurerm_shared_image_gallery.acg.id
  role_definition_name  = "Contributor"
  principal_id          = azurerm_user_assigned_identity.acg-umi.principal_id
}

# Set RBAC Permissions to Subscription
resource "azurerm_role_assignment" "acg-role-subscription-assignment" {
  scope                 = data.azurerm_subscription.subscription.id
  role_definition_name  = "Contributor"
  principal_id          = azurerm_user_assigned_identity.acg-umi.principal_id
}

# Set RBAC Permissions to Network Resource Group
resource "azurerm_role_assignment" "acg-role-vnet-assignment" {
  scope                 = data.azurerm_resource_group.vnetrg.id
  role_definition_name  = "Contributor"
  principal_id          = azurerm_user_assigned_identity.acg-umi.principal_id
}

# Create Image Definition -- This is required for the use of Packer as it can't create the Image Definition and must reference and existing. 
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/shared_image
resource "azurerm_shared_image" "image" {
  name                = var.avd-acg-image-name
  gallery_name        = azurerm_shared_image_gallery.acg.name
  resource_group_name = azurerm_resource_group.avdsharedresources.name
  location            = azurerm_resource_group.avdsharedresources.location
  os_type             = var.avd-acg-image-os_type
  hyper_v_generation  = var.avd-acg-image-hyper_v_generation

  identifier {
    publisher = var.avd-acg-image-publisher
    offer     = var.avd-acg-image-offer
    sku       = var.avd-acg-image-sku
  }
}

# Create Storage Account for managing Deployment Artifacts
resource "azurerm_storage_account" "avdsa" {
  name                      = var.avd-storageaccount-name
  resource_group_name       = azurerm_resource_group.avdsharedresources.name
  location                  = azurerm_resource_group.avdsharedresources.location
  tags                      = var.resourcetags
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
  shared_access_key_enabled = true
}

# Create Storage Account Container
resource "azurerm_storage_container" "avdcontainer" {
  name                  = "avd-deployment-artifacts"
  storage_account_name  = azurerm_storage_account.avdsa.name
  container_access_type = "private"
}

# Create Log Analytics Workspace
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace
resource "azurerm_log_analytics_workspace" "avdlaw" {
  name                = var.avd-law-name
  resource_group_name = azurerm_resource_group.avdsharedresources.name
  location            = azurerm_resource_group.avdsharedresources.location
  sku                 = var.avd-law-sku_name
  retention_in_days   = var.avd_law-retention_in_days
}

# Create Azure KeyVault
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault
resource "azurerm_key_vault" "avdkv" {
  name                            = var.avd-kv-name
  resource_group_name             = azurerm_resource_group.avdsharedresources.name
  location                        = azurerm_resource_group.avdsharedresources.location
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.avd-kv-sku
  enable_rbac_authorization       = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
}

# Create Password
resource "random_password" "avd_local_admin" {
  length = 64
}

# Add Secrets to KeyVault
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret
# TF App requires access to Key Vault Data Plane to execute this part

resource "azurerm_key_vault_secret" "avd_local_admin_password" {
  name              = "avd-local-admin-password"
  value             = random_password.avd_local_admin.result
  key_vault_id      = azurerm_key_vault.avdkv.id
}