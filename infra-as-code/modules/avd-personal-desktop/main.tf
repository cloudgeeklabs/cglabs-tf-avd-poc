// Load up Azure Tenant Configuration
data "azurerm_client_config" "current" {}

// Create Resource Group
resource "azurerm_resource_group" "rg_avd" {
  name     = var.resGroupName
  location = var.region
  tags = var.resourcetags
}


// Create AVD workspace
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
    name                = "${var.prefix}-workspace"
    resource_group_name = azurerm_resource_group.rg_avd.name
    location            = azurerm_resource_group.rg_avd.location
    tags                = var.resourcetags
    friendly_name       = "${var.prefix} Workspace"
    description         = "${var.prefix} Workspace"
}

// Create AVD host pool
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool.html
resource "azurerm_virtual_desktop_host_pool" "hostpool" {
    resource_group_name                 = azurerm_resource_group.rg_avd.name
    location                            = azurerm_resource_group.rg_avd.location
    tags                                = var.resourcetags
    name                                = "${var.prefix}-hostpool"
    friendly_name                       = "${var.prefix}-hostpool"
    start_vm_on_connect                 = var.start_vm_on_connect
    personal_desktop_assignment_type    = var.personal_desktop_assignment_type
    validate_environment                = var.validate_environment
    custom_rdp_properties               = var.custom_rdp_properties
    description                         = "${var.prefix}-hostpool"
    type                                = var.poolType
    maximum_sessions_allowed            = var.maximum_sessions_allowed
    load_balancer_type                  = var.load_balancer_type
}

// Create AVD DAG
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application_group
resource "azurerm_virtual_desktop_application_group" "dag" {
    resource_group_name                 = azurerm_resource_group.rg_avd.name
    host_pool_id                        = azurerm_virtual_desktop_host_pool.hostpool.id
    location                            = azurerm_resource_group.rg_avd.location
    tags                                = var.resourcetags
    type                                = var.DAG_Type
    name                                = "${var.prefix}-dag"
    friendly_name                       = "${var.prefix}-dag"
    description                         = "${var.prefix}-dag"
    depends_on                          = [azurerm_virtual_desktop_host_pool.hostpool, azurerm_virtual_desktop_workspace.workspace]
}

// Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
    application_group_id    = azurerm_virtual_desktop_application_group.dag.id
    workspace_id            = azurerm_virtual_desktop_workspace.workspace.id
}

