resource "azurerm_storage_account" "storage_account" {
  name                     = "secretfunctionstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_function_app" "function_app" {
  name                       = "secret-expiry-function"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.app_service_plan.id
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  os_type                    = "linux"
  version                    = "~3"

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
  }
}

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "secret-function-app-service-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app_function" "timer_function" {
  name            = "CheckExpiringSecrets"
  function_app_id = azurerm_function_app.function_app.id
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