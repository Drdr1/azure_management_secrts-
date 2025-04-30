# Create Event Grid System Topic for Key Vault
resource "azurerm_eventgrid_system_topic" "keyvault" {
  name                   = "evgt-keyvault-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  source_arm_resource_id = azurerm_key_vault.kv.id
  topic_type             = "Microsoft.KeyVault.vaults"
  tags                   = var.tags
}

# Create Event Grid Subscription for Secret Near Expiry events
resource "azurerm_eventgrid_system_topic_event_subscription" "secret_near_expiry" {
  name                = "sub-secret-near-expiry"
  system_topic        = azurerm_eventgrid_system_topic.keyvault.name
  resource_group_name = azurerm_resource_group.rg.name

  webhook_endpoint {
    # Use Logic App for initial deployment
    url = azurerm_logic_app_trigger_http_request.event_grid_trigger.callback_url
  }

  included_event_types = [
    "Microsoft.KeyVault.SecretNearExpiry",
    "Microsoft.KeyVault.SecretExpired"
  ]

  retry_policy {
    max_delivery_attempts = 30
    event_time_to_live    = 1440 # 24 hours in minutes
  }
}

# Output instructions for updating the webhook URL if using Function App
