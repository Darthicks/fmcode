provider "azurerm" {
  features {}
}

data "azurerm_client_config" "main" {}

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

resource "azurerm_network_interface" "main" {
  name                = "fmkb-dt-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = var.vm_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
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
  name                = var.key_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.main.tenant_id
  sku_name            = "standard"

#  soft_delete_enabled = true
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

# Commented out due to policy restrictions
# resource "azurerm_storage_account" "main" {
#   name                     = var.storage_account_name
#   resource_group_name      = azurerm_resource_group.main.name
#   location                 = azurerm_resource_group.main.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   allow_blob_public_access = false
# }

# Commented out as not needed
# resource "azurerm_app_service_plan" "main" {
#   name                = var.app_service_plan_name
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   sku {
#     tier = "Basic"
#     size = "B1"
#   }
# }

resource "azurerm_public_ip" "main" {
  name                = "fmkbdtpublicip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
}

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
    name      = "appgwIpConfig"
    subnet_id = azurerm_subnet.main.id
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
