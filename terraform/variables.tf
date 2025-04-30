variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "keyvault-automation-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "key_vault_name_prefix" {
  description = "Prefix for the Key Vault name (will be appended with random string)"
  type        = string
  default     = "kv-auto"
}

variable "app_registration_name" {
  description = "Name of the App Registration"
  type        = string
  default     = "terraform-service-principal"
}

variable "secret_expiry_days" {
  description = "Number of days until service principal secret expires"
  type        = number
  default     = 365
}

variable "notification_days_before_expiry" {
  description = "Number of days before expiry to send notification"
  type        = number
  default     = 30
}

variable "azure_devops_org_url" {
  description = "Azure DevOps organization URL"
  type        = string
}

variable "azure_devops_pat" {
  description = "Azure DevOps Personal Access Token"
  type        = string
  sensitive   = true
}

variable "azure_devops_project_name" {
  description = "Azure DevOps project name"
  type        = string
}

variable "service_connection_name" {
  description = "Name for the Azure DevOps service connection"
  type        = string
  default     = "Terraform-Azure-Connection"
}

variable "email_recipients" {
  description = "List of email addresses to notify about expiring secrets"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "use_email_notifications" {
  description = "Enable email notifications"
  type        = bool
  default     = true
}

variable "use_slack_notifications" {
  description = "Enable Slack notifications"
  type        = bool
  default     = false
}

# New variables for SendGrid email integration
variable "sendgrid_api_key" {
  description = "SendGrid API Key for sending emails"
  type        = string
  default     = ""
  sensitive   = true
}

variable "email_from" {
  description = "Email address to send notifications from"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}