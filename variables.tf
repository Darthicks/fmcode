variable "resource_group_name" {
  description = "The name of the resource group where resources will be created."
  type        = string
  default     = "fmkb-dt-dta01-rg"
}
 
variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "swedensouth"
}
 
variable "vm_name" {
  description = "The name of the virtual machine."
  type        = string
  default     = "fmkb_dt_vm"
}
 
variable "aci_name" {
  description = "The name of the Azure Container Instance."
  type        = string
  default     = "fmkb_dt_aci"
}
 
variable "key_vault_name" {
  description = "The name of the Azure Key Vault."
  type        = string
  default     = "fmkb_dt_keyvault"
}
 
variable "storage_account_name" {
  description = "The name of the Storage Account."
  type        = string
  default     = "fmkbdtstorage"
}
 
variable "app_gateway_name" {
  description = "The name of the Application Gateway."
  type        = string
  default     = "fmkb_dt_appgw"
}
 
variable "vnet_name" {
  description = "The name of the Virtual Network."
  type        = string
  default     = "fmkb_dt_vnet"
}
 
variable "subnet_name" {
  description = "The name of the Subnet."
  type        = string
  default     = "fmkb_dt_subnet"
}
 
variable "nsg_name" {
  description = "The name of the Network Security Group."
  type        = string
  default     = "fmkb_dt_nsg"
}
 
variable "app_service_name" {
  description = "The name of the App Service for Azure Functions."
  type        = string
  default     = "fmkb_dt_appservice"
}
 
variable "private_link_name" {
  description = "The name of the Private Link."
  type        = string
  default     = "fmkb_dt_plink"
}
