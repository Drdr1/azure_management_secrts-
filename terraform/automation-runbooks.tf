resource "azurerm_automation_account" "automation_account" {
  name                = "secret-automation-account-${random_id.suffix.hex}"  # Append a random suffix
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"
  identity {
    type = "SystemAssigned"  # Enable System-assigned Managed Identity
  }
}
resource "azurerm_automation_runbook" "runbook" {
  name                    = "check-expiring-secrets"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation_account.name
  runbook_type            = "PowerShell"
  log_progress            = true
  log_verbose             = true
  content = <<EOF
  # Retrieve SPN credentials from variables (passed via Terraform provider)
  $clientId = "${var.azure_client_id}"
  $clientSecret = "${var.azure_client_secret}"
  $tenantId = "${var.azure_tenant_id}"

  # Authenticate with SPN
  $secureSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
  $credential = New-Object System.Management.Automation.PSCredential ($clientId, $secureSecret)
  Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId

  # Get Slack token from Key Vault
  $slackToken = (Get-AzKeyVaultSecret -VaultName "${var.key_vault_name}" -Name "slack-token").SecretValueText

  # Get secrets
  $Secrets = Get-AzKeyVaultSecret -VaultName "${var.key_vault_name}"
  foreach ($Secret in $Secrets) {
      if ($Secret.Expires -lt (Get-Date).AddDays(7)) {
          # Post to Slack
          $url = "https://slack.com/api/chat.postMessage"
          $headers = @{ "Authorization" = "Bearer $slackToken"; "Content-Type" = "application/json" }
          $body = @{
              channel = "#general"
              text = "Secret $($Secret.Name) expires on $($Secret.Expires)"
          } | ConvertTo-Json
          Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
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
  start_time              = "2025-04-08T20:00:00Z"  # Corrected date format
}

resource "azurerm_automation_job_schedule" "runbook_schedule" {
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation_account.name
  runbook_name            = azurerm_automation_runbook.runbook.name
  schedule_name           = azurerm_automation_schedule.daily_schedule.name
}
