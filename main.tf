provider "azurerm" {
  features {}
  subscription_id = "07fba911-b0ce-4b88-993a-79b8e5de293a"
  resource_provider_registrations = "none"
}

data "azurerm_client_config" "main" {}

data "azurerm_resource_group" "existing" {
  name = "fmkb-dt-dta01-rg"
}

resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
}

resource "azurerm_subnet" "main" {
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_resource_group.existing.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# New dedicated subnet for Application Gateway
resource "azurerm_subnet" "app_gateway_subnet" {
  name                 = "appGatewaySubnet"
  resource_group_name  = data.azurerm_resource_group.existing.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]  # Ensure this does not overlap with other subnets
}

resource "azurerm_network_security_group" "main" {
  name                = var.nsg_name
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
}

resource "azurerm_network_interface" "main" {
  name                = "fmkb-dt-nic"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = var.vm_name
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  size                = "Standard_DS1_v2"

  admin_username = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("${path.module}/ssh_key.pub")  # Ensure this file exists
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_key_vault" "main" {
  name                = var.keyvault_name  # Change this to a unique name
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  tenant_id           = data.azurerm_client_config.main.tenant_id
  sku_name            = "standard"

  # soft_delete_enabled = true
}

resource "azurerm_container_group" "main" {
  name                = var.aci_name
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
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

# Commented out due to policy restrictions
# resource "azurerm_storage_account" "main" {
#   name                     = var.storage_account_name
#   resource_group_name      = data.azurerm_resource_group.existing.name
#   location                 = data.azurerm_resource_group.existing.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   allow_blob_public_access = false
# }

# Commented out as not needed
# resource "azurerm_app_service_plan" "main" {
#   name                = var.app_service_plan_name
#   location            = data.azurerm_resource_group.existing.location
#   resource_group_name = data.azurerm_resource_group.existing.name
#   sku {
#     tier = "Basic"
#     size = "B1"
#   }
# }

resource "azurerm_public_ip" "main" {
  name                = "fmkbdtpublicip"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  allocation_method   = "Static"  # Changed to Static for Standard SKU
  sku                 = "Standard" # Specify Standard SKU
}

resource "azurerm_application_gateway" "main" {
  name                = var.app_gateway_name
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgwIpConfig"
    subnet_id = azurerm_subnet.app_gateway_subnet.id  # Use new subnet for Application Gateway
  }

  frontend_ip_configuration {
    name                 = "appgwFrontendIpConfig"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  frontend_port {
    name = "httpPort"
    port = 80
  }

  backend_address_pool {
    name = "appgwBackendPool"
  }

  backend_http_settings {
    name                  = "appgwBackendHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "appgwHttpListener"
    frontend_ip_configuration_name = "appgwFrontendIpConfig"
    frontend_port_name             = "httpPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "appgwRequestRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = "appgwHttpListener"
    backend_address_pool_name  = "appgwBackendPool"
    backend_http_settings_name = "appgwBackendHttpSettings"
    priority                   = 1
  }
}
