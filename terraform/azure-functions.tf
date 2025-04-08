
resource "azurerm_storage_account" "storage_account" {
  name                     = "secretstore${random_id.suffix.hex}"  # Shorter name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "secret-function-app-service-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"  # Ensure this is set to "Linux"
  sku_name            = "Y1"     # Consumption plan
}

resource "azurerm_linux_function_app" "function_app" {
  name                       = "secret-expiry-function-${random_id.suffix.hex}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.app_service_plan.id
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
    "AZURE_CLIENT_ID"          = var.azure_client_id
    "AZURE_CLIENT_SECRET"      = var.azure_client_secret
    "AZURE_TENANT_ID"          = var.azure_tenant_id
    "SLACK_TOKEN"              = var.slack_token
  }
}

resource "azurerm_function_app_function" "timer_function" {
  name            = "CheckExpiringSecrets"
  function_app_id = azurerm_linux_function_app.function_app.id
  config_json = jsonencode({
    bindings = [
      {
        type      = "timerTrigger"
        direction = "in"
        name      = "myTimer"
        schedule  = "0 0 8 * * *"  # Daily at 08:00 UTC
      }
    ]
  })
}

