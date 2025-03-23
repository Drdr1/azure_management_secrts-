
resource "azurerm_storage_account" "storage_account" {
  name                     = "secretfunctionstorage${random_id.suffix.hex}"  # Append a random suffix
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
  name                       = "secret-expiry-function"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.app_service_plan.id
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key

  site_config {
    application_stack {
      dotnet_version = "6.0"  # Specify the .NET version
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
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
        schedule  = "0 0 8 * * *"
      }
    ]
  })
}
