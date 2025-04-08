# Logic App Workflow
resource "azurerm_logic_app_workflow" "logic_app" {
  name                = "secret-expiry-notification"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workflow_parameters = {
    "$connections"  = jsonencode({
      "azurekeyvault" = {
        "connectionId"   = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/connections/azurekeyvault"
        "connectionName" = "azurekeyvault"
        "id"             = "/subscriptions/${var.azure_subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/azurekeyvault"
      }
    })
    "slack_token"   = var.slack_token
    "tenant_id"     = var.azure_tenant_id
    "client_id"     = var.azure_client_id
    "client_secret" = var.azure_client_secret
  }
}

# Recurrence Trigger (Daily at 10:00 PM Cairo = 20:00 UTC)
resource "azurerm_logic_app_trigger_recurrence" "daily_trigger" {
  name         = "daily-trigger"
  logic_app_id = azurerm_logic_app_workflow.logic_app.id
  frequency    = "Day"
  interval     = 1
  start_time   = "2025-04-08T20:00:00Z"  # 10:00 PM Cairo time
}

# Action: List Secrets from Key Vault
resource "azurerm_logic_app_action_custom" "key_vault_action" {
  name         = "list-secrets"
  logic_app_id = azurerm_logic_app_workflow.logic_app.id
  body = jsonencode({
    "type" = "ApiConnection"
    "inputs" = {
      "host" = {
        "connection" = {
          "name" = "@parameters('$connections')['azurekeyvault']['connectionId']"
        }
      }
      "method" = "GET"
      "path"   = "/secrets"
      "authentication" = {
        "type"     = "ActiveDirectoryOAuth"
        "tenant"   = "@parameters('tenant_id')"
        "clientId" = "@parameters('client_id')"
        "secret"   = "@parameters('client_secret')"
        "audience" = "https://vault.azure.net"
      }
    }
  })
}

# Action: For Each Loop and Condition with runAfter
resource "azurerm_logic_app_action_custom" "for_each_and_notify" {
  name         = "check-and-notify"
  logic_app_id = azurerm_logic_app_workflow.logic_app.id
  body = jsonencode({
    "type"    = "Foreach"
    "foreach" = "@body('list-secrets')?['value']"
    "actions" = {
      "Condition" = {
        "type" = "If"
        "expression" = {
          "and" = [
            {
              "less" = [
                "@items('check-and-notify')?['attributes']?['expires']",
                "@addDays(utcNow(), 7)"
              ]
            }
          ]
        }
        "actions" = {
          "Post_to_Slack" = {
            "type" = "Http"
            "inputs" = {
              "method" = "POST"
              "uri"    = "https://slack.com/api/chat.postMessage"
              "headers" = {
                "Authorization" = "Bearer @{parameters('slack_token')}"
                "Content-Type"  = "application/json"
              }
              "body" = {
                "channel" = "#general"
                "text"    = "Secret @{items('check-and-notify')?['name']} expires on @{items('check-and-notify')?['attributes']?['expires']}"
              }
            }
          }
        }
      }
    }
    "runAfter" = {
      "list-secrets" = ["Succeeded"]
    }
  })
  depends_on = [azurerm_logic_app_action_custom.key_vault_action]
}