provider "azurerm" {

  features = {}

}
 
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

  }
 
  os_profile {

    computer_name  = var.vm_name

    admin_username = "adminuser"

    admin_password = "P@ssw0rd123!"

  }
 
  os_profile_linux_config {

    disable_password_authentication = false

  }
 
  source_image_reference {

    publisher = "Canonical"

    offer     = "UbuntuServer"

    sku       = "18.04-LTS"

    version   = "latest"

  }

}
 
resource "azurerm_network_interface" "main" {

  name                = "${var.vm_name}-nic"

  location            = var.location

  resource_group_name = var.resource_group_name
 
  ip_configuration {

    name                          = "internal"

    subnet_id                     = azurerm_subnet.main.id

    private_ip_address_allocation = "Dynamic"

  }

}
 
resource "azurerm_container_group" "main" {

  name                = var.aci_name

  location            = var.location

  resource_group_name = var.resource_group_name

  os_type             = "Linux"
 
  container {

    name   = "mycontainer"

    image  = "nginx"

    cpu    = "0.5"

    memory = "1.5"
 
    ports {

      port     = 80

      protocol = "TCP"

    }

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
 
resource "azurerm_application_gateway" "main" {

  name                = var.app_gateway_name

  location            = var.location

  resource_group_name = var.resource_group_name

  sku {

    name     = "Standard_v2"

    tier     = "Standard_v2"

    capacity = 2

  }
 
  gateway_ip_configuration {

    name      = "appgw-ip-config"

    subnet_id = azurerm_subnet.main.id

  }
 
  frontend_port {

    name = "frontendPort"

    port = 80

  }
 
  frontend_ip_configuration {

    name                 = "frontendIP"

    public_ip_address_id = azurerm_public_ip.main.id

  }
 
  backend_address_pool {

    name = "backendPool"

  }
 
  http_listener {

    name                           = "listener"

    frontend_ip_configuration_name = "frontendIP"

    frontend_port_name             = "frontendPort"

    protocol                       = "Http"

  }
 
  backend_http_settings {

    name                  = "httpSetting"

    cookie_based_affinity = "Disabled"

    port                  = 80

    protocol              = "Http"

  }
 
  request_routing_rule {

    name                       = "rule1"

    rule_type                  = "Basic"

    http_listener_name         = "listener"

    backend_address_pool_name  = "backendPool"

    backend_http_settings_name = "httpSetting"

  }

}
 
resource "azurerm_app_service" "main" {

  name                = var.app_service_name

  location            = var.location

  resource_group_name = var.resource_group_name

  app_service_plan_id = azurerm_app_service_plan.main.id
 
  app_settings = {

    "WEBSITE_RUN_FROM_PACKAGE" = "1"

  }

}
 
resource "azurerm_app_service_plan" "main" {

  name                = "${var.app_service_name}-plan"

  location            = var.location

  resource_group_name = var.resource_group_name

  sku {

    tier = "Dynamic"

    size = "Y1"

  }

}
 
resource "azurerm_private_endpoint" "main" {

  name                = var.private_link_name

  location            = var.location

  resource_group_name = var.resource_group_name

  subnet_id           = azurerm_subnet.main.id
 
  private_service_connection {

    name                           = "privateserviceconnection"

    private_connection_resource_id = azurerm_storage_account.main.id

    is_manual_connection           = false

    subresource_names              = ["blob"]

  }

}
 
resource "azurerm_public_ip" "main" {

  name                = "${var.vm_name}-pip"

  location            = var.location

  resource_group_name = var.resource_group_name

  allocation_method   = "Dynamic"

}

 