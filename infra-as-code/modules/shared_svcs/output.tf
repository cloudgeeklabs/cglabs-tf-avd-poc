output "ResourceGroupName" {
  description = "ResourceGroup Name"
  value       = azurerm_resource_group.avdsharedresources.name
}

output "ComputeGalleryName" {
  description = "Azure Compute Gallery"
  value       = azurerm_shared_image_gallery.acg.name
}

output "KeyVaultName" {
  description = "KeyVault Name"
  value       = azurerm_key_vault.avdkv.name
}

output "Image_Name" {
  value       = azurerm_shared_image.image.name
}

output "ACG_Id" {
  value       = azurerm_shared_image_gallery.acg.id
}

output "AVDLAWId" {
  value       = azurerm_log_analytics_workspace.avdlaw.id
}

output "AVDArtifactsURL" {
  value       = azurerm_storage_account.avdsa.id
}

output "app_clientSecret" {
    value = azuread_application_password.packer.value
    sensitive = true
}

output "packer_clientId_SecretName" {
  value = azurerm_key_vault_secret.client_id.name
}

output "packer_clientSecret_SecretName" {
  value = azurerm_key_vault_secret.client_secret.name
}
