# Create Azure AD Application
resource "azuread_application" "app" {
  display_name = var.app_registration_name
}

# Create Service Principal associated with the application
resource "azuread_service_principal" "sp" {
  # Fix: Use client_id instead of application_id
  client_id = azuread_application.app.client_id
}

# Create a password for the Service Principal
resource "azuread_application_password" "sp_password" {
  application_object_id = azuread_application.app.object_id
  display_name          = "terraform-managed"
  end_date_relative     = "${var.secret_expiry_days * 24}h" # Convert days to hours
}

# Note: Role assignment removed as it requires Owner or User Access Administrator role
# If you need this, you'll need to assign it manually or use a service principal
# with sufficient permissions to run Terraform

# Get current subscription details
data "azurerm_subscription" "current" {}

# Store Service Principal credentials in Key Vault
resource "azurerm_key_vault_secret" "sp_client_id" {
  name         = "${var.app_registration_name}-client-id"
  value        = azuread_application.app.client_id # Fix: Use client_id instead of application_id
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "text/plain"
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "sp_client_secret" {
  name         = "${var.app_registration_name}-client-secret"
  value        = azuread_application_password.sp_password.value
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "text/plain"
  
  # Set expiration date to match the service principal password
  expiration_date = timeadd(timestamp(), "${var.secret_expiry_days * 24}h")
  
  tags = merge(var.tags, {
    ExpiryDate = timeadd(timestamp(), "${var.secret_expiry_days * 24}h")
  })
}

# Grant the Service Principal access to the Key Vault
resource "azurerm_key_vault_access_policy" "sp_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azuread_service_principal.sp.object_id

  secret_permissions = [
    "Get", "List",
  ]
}