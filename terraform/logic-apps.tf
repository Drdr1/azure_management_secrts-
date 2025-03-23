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