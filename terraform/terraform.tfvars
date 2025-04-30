# Resource naming and location
resource_group_name    = "keyvault-automation-rg"
location               = "East US"
key_vault_name_prefix  = "kv-auto"
app_registration_name  = "terraform-service-principal"

# Secret expiration settings
secret_expiry_days            = 365
notification_days_before_expiry = 30

# Azure DevOps settings
azure_devops_org_url       = "https://dev.azure.com/si-amd/"
azure_devops_pat           =  "" 
azure_devops_project_name  = "si-amd-azappgw-kong-mosaicai"
service_connection_name    = "Terraform-Azure-Connection"

# Notification settings 
email_recipients = [
  "ahmeddarder157@gmail.com",
  "shadowridgeroad@gmail.com "
]
slack_webhook_url        = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
use_email_notifications  = true
use_slack_notifications  = true

# SendGrid Email Configuration
sendgrid_api_key = "" # Get this from SendGrid
email_from       = "ahmeddarder709@gmail.com" # Verified sender in SendGrid

# Resource tags
tags = {
  Environment = "Production"
  ManagedBy   = "Terraform"
  Project     = "Secret-Automation"
}