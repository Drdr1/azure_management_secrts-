variable "azure_tenant_id" {
  description = "Tenant ID for Azure authentication"
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Subscription ID for Azure authentication"
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  description = "Client ID for Azure authentication"
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Client Secret for Azure authentication"
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "secret-management-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}
