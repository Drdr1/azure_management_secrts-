
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "secret-management-rg-${random_id.suffix.hex}"  # Append a random suffix
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

resource "random_id" "suffix" {
  byte_length = 4  # Generates a 4-byte (8-character) random suffix
}
