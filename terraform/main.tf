## Solution 1: Azure Logic Apps
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "secret-management-rg"
  location = "East US"
}

resource "azurerm_logic_app_workflow" "logic_app" {
  name                = "secret-expiry-notification"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_logic_app_trigger_recurrence" "daily_trigger" {
  name         = "daily-trigger"
  logic_app_id = azurerm_logic_app_workflow.logic_app.id
  frequency    = "Day"
  interval     = 1
}

resource "azurerm_logic_app_action_custom" "key_vault_action" {
  name         = "key-vault-action"
  logic_app_id = azurerm_logic_app_workflow.logic_app.id
  body = jsonencode({
    type = "ApiConnection"
    inputs = {
      host = {
        connection = {
          name = "@parameters('$connections')['azurekeyvault']['connectionId']"
        }
      }
      method = "GET"
      path   = "/secrets"
    }
  })
}

resource "azurerm_logic_app_action_custom" "slack_notification" {
  name         = "slack-notification"
  logic_app_id = azurerm_logic_app_workflow.logic_app.id
  body = jsonencode({
    type = "ApiConnection"
    inputs = {
      host = {
        connection = {
          name = "@parameters('$connections')['slack']['connectionId']"
        }
      }
      method = "POST"
      path   = "/chat.postMessage"
      body   = {
        channel = "#general"
        text    = "A secret is expiring soon!"
      }
    }
  })
}


##Solution 2: Azure Automation Runbooks

resource "azurerm_automation_account" "automation_account" {
  name                = "secret-automation-account"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"
}

resource "azurerm_automation_runbook" "runbook" {
  name                    = "check-expiring-secrets"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation_account.name
  runbook_type            = "PowerShell"
  content = <<EOF
# PowerShell script to check expiring secrets
Connect-AzAccount
$Secrets = Get-AzKeyVaultSecret -VaultName "YourKeyVaultName"
foreach ($Secret in $Secrets) {
    if ($Secret.Expires -lt (Get-Date).AddDays(7)) {
        Send-MailMessage -To "user@example.com" -Subject "Secret Expiring Soon" -Body "Secret $($Secret.Name) is expiring on $($Secret.Expires)."
    }
}
EOF
}

resource "azurerm_automation_schedule" "daily_schedule" {
  name                    = "daily-schedule"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation_account.name
  frequency               = "Day"
  interval                = 1
  start_time              = "2023-10-01T08:00:00Z"
}

resource "azurerm_automation_job_schedule" "runbook_schedule" {
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation_account.name
  runbook_name            = azurerm_automation_runbook.runbook.name
  schedule_name           = azurerm_automation_schedule.daily_schedule.name
}


## Solution 3: Azure Functions

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
