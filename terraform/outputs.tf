output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "app_registration_name" {
  description = "Name of the App Registration"
  value       = azuread_application.app.display_name
}

output "app_registration_application_id" {
  description = "Application ID (Client ID) of the App Registration"
  value       = azuread_application.app.application_id
}

output "service_principal_object_id" {
  description = "Object ID of the Service Principal"
  value       = azuread_service_principal.sp.object_id
}

output "service_principal_secret_expiry" {
  description = "Expiry date of the Service Principal secret"
  value       = timeadd(timestamp(), "${var.secret_expiry_days * 24}h")
}

output "azure_devops_service_connection_name" {
  description = "Name of the Azure DevOps service connection"
  value       = azuredevops_serviceendpoint_azurerm.serviceendpoint.service_endpoint_name
}

output "logic_app_workflow_name" {
  description = "Name of the Logic App workflow for notifications"
  value       = azurerm_logic_app_workflow.secret_expiry_notification.name
}

output "event_grid_system_topic_name" {
  description = "Name of the Event Grid system topic"
  value       = azurerm_eventgrid_system_topic.keyvault.name
}

output "notification_days_before_expiry" {
  description = "Number of days before expiry when notifications will be sent"
  value       = var.notification_days_before_expiry
}

output "function_app_name" {
  value = var.use_email_notifications ? azurerm_windows_function_app.email_function[0].name : "Email notifications disabled"
}

output "function_app_resource_group" {
  value = var.use_email_notifications ? azurerm_resource_group.rg.name : "Email notifications disabled"
}

