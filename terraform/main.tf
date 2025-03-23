provider "azurerm" {
  features {}

  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
