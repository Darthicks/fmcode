provider "azurerm" {
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "main" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_interface" "main" {
  name                = "fmkb_dt_nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_D4as_v5"

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
    disk_size_gb      = 128
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = var.vm_name
    admin_username = "adminuser"
    admin_password = "P@ssw0rd123!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_container_group" "main" {
  name                = var.aci_name
  location            = var.location
  resource_group_name = var.resource_group_name
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

  ip_address_type = "Public"
  dns_name_label  = "${var.aci_name}-dns"
  tags = {
    environment = "testing"
  }
}

resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_public_ip" "main" {
  name                = "fmkb_dt_public_ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "main" {
  name                = var.app_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgwIpConfig"
    subnet_id = azurerm_subnet.main.id
  }

  frontend_port {
    name = "httpPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgwFrontendIpConfig"
    public_ip_address_id = azurerm_public_ip.main.id
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
  }
}

resource "azurerm_private_endpoint" "main" {
  name                = var.private_link_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.main.id

  private_service_connection {
    name                           = "privateConnection"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

resource "azurerm_service_plan" "main" {
  name                = "fmkb_dt_asp"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  os_type = "Linux"
}

resource "azurerm_function_app" "main" {
  name                 = var.app_service_name
  location             = var.location
  resource_group_name  = var.resource_group_name
  app_service_plan_id  = azurerm_service_plan.main.id
  storage_account_name = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  version              = "~3"
}

output "function_app_id" {
  value = azurerm_function_app.main.id
}
