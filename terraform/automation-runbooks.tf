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
  log_progress            = true  # Required argument
  log_verbose             = true  # Required argument
  content = <<EOF
# Get secrets from Azure Key Vault
$Secrets = Get-AzKeyVaultSecret -VaultName "YourKeyVaultName"
foreach ($Secret in $Secrets) {
    if ($Secret.Expires -lt (Get-Date).AddDays(7)) {
        # Send email notification
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
  start_time              = "2025-04-01T08:00:00Z"  # Corrected date format
}

resource "azurerm_automation_job_schedule" "runbook_schedule" {
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation_account.name
  runbook_name            = azurerm_automation_runbook.runbook.name
  schedule_name           = azurerm_automation_schedule.daily_schedule.name
}
