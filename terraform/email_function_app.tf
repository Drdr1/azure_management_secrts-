# Create storage account for Function App
resource "azurerm_storage_account" "function_storage" {
  count                    = var.use_email_notifications ? 1 : 0
  name                     = "funcsa${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Create App Service Plan for Function App
resource "azurerm_service_plan" "function_plan" {
  count               = var.use_email_notifications ? 1 : 0
  name                = "asp-function-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = "Y1" # Consumption plan
  tags                = var.tags
}

# Create Function App for email notifications
resource "azurerm_windows_function_app" "email_function" {
  count               = var.use_email_notifications ? 1 : 0
  name                = "func-email-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  storage_account_name       = azurerm_storage_account.function_storage[0].name
  storage_account_access_key = azurerm_storage_account.function_storage[0].primary_access_key
  service_plan_id            = azurerm_service_plan.function_plan[0].id
  
  site_config {
    application_stack {
      node_version = "~16"
    }
    cors {
      allowed_origins = ["https://portal.azure.com"]
    }
  }
  
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "node"
    "WEBSITE_NODE_DEFAULT_VERSION" = "~16"
    "WEBSITE_RUN_FROM_PACKAGE"     = "1"
    "EMAIL_RECIPIENTS"             = join(",", var.email_recipients)
    "SENDGRID_API_KEY"             = var.sendgrid_api_key
    "EMAIL_FROM"                   = var.email_from
  }
  
  tags = var.tags
}

