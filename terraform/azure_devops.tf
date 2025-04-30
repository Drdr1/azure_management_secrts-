# Get Azure DevOps project
data "azuredevops_project" "project" {
  name = var.azure_devops_project_name
}

# Create Azure DevOps service connection
resource "azuredevops_serviceendpoint_azurerm" "serviceendpoint" {
  project_id            = data.azuredevops_project.project.id
  service_endpoint_name = var.service_connection_name
  description           = "Managed by Terraform"
  
  credentials {
    # Fix: Use client_id instead of application_id
    serviceprincipalid  = azuread_application.app.client_id
    serviceprincipalkey = azuread_application_password.sp_password.value
  }
  
  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = data.azurerm_subscription.current.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.current.display_name
}

# Grant access to all pipelines
resource "azuredevops_resource_authorization" "serviceendpoint_auth" {
  project_id  = data.azuredevops_project.project.id
  resource_id = azuredevops_serviceendpoint_azurerm.serviceendpoint.id
  authorized  = true
}