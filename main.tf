provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_container_group" "main" {
  name                = var.aci_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"

  container {
    name   = "nginx"
    image  = "nginx:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = {
    environment = "testing"
  }
}

# resource "azurerm_storage_account" "main" {
#   name                     = var.storage_account_name
#   resource_group_name       = azurerm_resource_group.main.name
#   location                  = azurerm_resource_group.main.location
#   account_tier              = "Standard"
#   account_replication_type  = "LRS"
#   allow_blob_public_access  = false  # Disable public access as per policy
# }

# resource "azurerm_app_service_plan" "main" {
#   name                = var.app_service_plan_name
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   sku {
#     tier = "Basic"
#     size = "B1"
#   }
# }

resource "azurerm_application_gateway" "main" {
  name                = var.app_gateway_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgatewayipconfig"
    subnet_id = azurerm_subnet.main.id
  }

  # Additional configuration for the Application Gateway (listeners, etc.)
}
