# main.tf

# Generate a random suffix
resource "random_id" "suffix" {
  byte_length = 4  # Generates a 4-byte (8-character) random suffix
}

# Define the Resource Group with a unique name
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name  # Append a random suffix
  location = var.location
}

resource "azurerm_key_vault" "kv" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = var.azure_tenant_id
  sku_name                    = "standard"  # Options: "standard" or "premium"
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  enabled_for_template_deployment = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  # Access policy for the Service Principal (to manage secrets)
  access_policy {
    tenant_id = var.azure_tenant_id
     object_id = data.azurerm_client_config.current.object_id  # SPN object ID    
     secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]
  
}
}
data "azurerm_client_config" "current" {}


resource "azurerm_key_vault_secret" "test_secret" {
  name         = "test-secret"
  value        = "mysecretvalue"
  key_vault_id = azurerm_key_vault.kv.id
  expiration_date = "2025-04-08T20:10:00Z"  
}

output "slack_token_debug" {
  value = var.slack_token
  sensitive = true
}