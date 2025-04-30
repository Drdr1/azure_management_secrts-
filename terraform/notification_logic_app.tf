# Create Logic App for notifications
resource "azurerm_logic_app_workflow" "secret_expiry_notification" {
  name                = "logic-secret-expiry-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Create Logic App trigger for HTTP requests
resource "azurerm_logic_app_trigger_http_request" "event_grid_trigger" {
  name         = "event-grid-trigger"
  logic_app_id = azurerm_logic_app_workflow.secret_expiry_notification.id

  schema = <<SCHEMA
{
  "type": "object",
  "properties": {
    "topic": {
      "type": "string"
    },
    "subject": {
      "type": "string"
    },
    "eventType": {
      "type": "string"
    },
    "eventTime": {
      "type": "string"
    },
    "id": {
      "type": "string"
    },
    "data": {
      "type": "object",
      "properties": {
        "VaultName": {
          "type": "string"
        },
        "ObjectType": {
          "type": "string"
        },
        "ObjectName": {
          "type": "string"
        },
        "Version": {
          "type": "string"
        },
        "NBF": {
          "type": ["string", "null"]
        },
        "EXP": {
          "type": ["string", "number", "null"]
        }
      }
    },
    "dataVersion": {
      "type": "string"
    }
  }
}
SCHEMA
}

# Create Logic App action for Slack notification
resource "azurerm_logic_app_action_http" "send_slack" {
  count        = var.use_slack_notifications ? 1 : 0
  name         = "send-slack-notification"
  logic_app_id = azurerm_logic_app_workflow.secret_expiry_notification.id
  method       = "POST"
  uri          = var.slack_webhook_url
  body = jsonencode({
    "text": "Secret Expiration Alert",
    "blocks": [
      {
        "type": "header",
        "text": {
          "type": "plain_text",
          "text": "⚠️ Secret Expiration Alert"
        }
      },
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*The following secret is nearing expiration:*\n\n*Key Vault:* @{triggerBody()?['data']?['VaultName']}\n*Secret Name:* @{triggerBody()?['data']?['ObjectName']}\n*Expiration Date:* @{formatDateTime(addSeconds('1970-01-01', triggerBody()?['data']?['EXP']), 'yyyy-MM-dd')}"
        }
      },
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "Please take action to rotate this secret before it expires."
        }
      }
    ]
  })
  headers = {
    "Content-Type" = "application/json"
  }
}