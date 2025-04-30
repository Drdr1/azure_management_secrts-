# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Generate a random suffix for globally unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "${var.key_vault_name_prefix}-${random_string.suffix.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  # Grant permissions to the current user/service principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover",
    ]

    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]
  }

  tags = var.tags
}

# Create a diagnostic setting for Key Vault to enable monitoring
resource "azurerm_monitor_diagnostic_setting" "kv_diag" {
  name                       = "kv-diagnostics"
  target_resource_id         = azurerm_key_vault.kv.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "AuditEvent"

    # retention_policy {
    #   enabled = true
    #   days    = 30
    # }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    # retention_policy {
    #   enabled = true
    #   days    = 30
    # }
  }
}

# Create Log Analytics Workspace for diagnostics
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}