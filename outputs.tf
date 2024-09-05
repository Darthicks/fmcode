output "vm_id" {
  value = azurerm_linux_virtual_machine.main.id
}


output "aci_id" {
  value = azurerm_container_group.main.id
}

output "key_vault_id" {
  value = azurerm_key_vault.main.id
}

# output "storage_account_id" {
#  value = azurerm_storage_account.main.id
# }

output "app_gateway_id" {
  value = azurerm_application_gateway.main.id
}

# output "function_app_id" {
 # value = azurerm_function_app.main.id
# }

output "private_link_id" {
  value = azurerm_private_endpoint.main.id
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "subnet_id" {
  value = azurerm_subnet.main.id
}

output "nsg_id" {
  value = azurerm_network_security_group.main.id
}
