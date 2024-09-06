# Default AzureRM Provider
provider "azurerm" {
  features {}
  skip_provider_registration = true
subscription_id = "07fba911-b0ce-4b88-993a-79b8e5de293a"
}

# Custom AzureRM CCoE Provider
provider "azurerm" {
  features {}
  skip_provider_registration = true
  alias                      = "ccoe"
  subscription_id            = "19a5edd0-42d3-4b5f-88b5-45f718494ad3"
}

# Resource Group Data Source
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Subnet Data Source
data "azurerm_subnet" "frontend01_subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.network_resource_group_name
  virtual_network_name = var.virtual_network_name
}

# Private Endpoint for Blob Storage
resource "azurerm_private_endpoint" "blob" {
  name                = "${random_string.random.result}-blob-endpoint"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.frontend01_subnet.id

  private_service_connection {
    name                           = "${random_string.random.result}-privateserviceconnection-blob"
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

# Private DNS Record for Blob Private Link
resource "azurerm_private_dns_a_record" "private_endpoint_a_record_blob" {
  provider            = azurerm.ccoe
  name                = azurerm_storage_account.sa.name
  zone_name           = "privatelink.blob.core.windows.net"
  resource_group_name = "dns-mgt01-rg"
  ttl                 = 300
  records             = [azurerm_private_endpoint.blob.private_service_connection[0].private_ip_address]
}

# Storage Account
resource "azurerm_storage_account" "sa" {
  name                            = var.name
  tags                            = var.tags
  account_kind                    = var.account_kind
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  allow_blob_public_access         = false # No public access to blobs
  allow_nested_items_to_be_public  = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

# Random String for Unique Naming
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}
