# main.tf

# Generate a random suffix
resource "random_id" "suffix" {
  byte_length = 4  # Generates a 4-byte (8-character) random suffix
}

# Define the Resource Group with a unique name
resource "azurerm_resource_group" "rg" {
  name     = "secret-management-rg-${random_id.suffix.hex}"  # Append a random suffix
  location = var.location
}
