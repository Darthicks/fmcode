variable "resource_group_name" {
  description = "The name of the resource group where resources will be created."
  type        = string
  default     = "fmkb-dt-dta01-rg"
}
 
variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "swedencentral"
}
 
variable "vm_name" {
  description = "The name of the virtual machine."
  type        = string
  default     = "fmkbdtvm"
}
 
variable "aci_name" {
  description = "The name of the Azure Container Instance."
  type        = string
  default     = "fmkbdtaci"
}
 
variable "key_vault_name" {
  description = "The name of the Azure Key Vault."
  type        = string
  default     = "fmkbdtkeyvault"
}
 
# variable "storage_account_name" {
#  description = "The name of the Storage Account."
#  type        = string
#  default     = "fmkbdtstoragesc"
# }
 
variable "app_gateway_name" {
  description = "The name of the Application Gateway."
  type        = string
  default     = "fmkbdtappgw"
}
 
variable "vnet_name" {
  description = "The name of the Virtual Network."
  type        = string
  default     = "fmkbdtvnet"
}
 
variable "subnet_name" {
  description = "The name of the Subnet."
  type        = string
  default     = "fmkbdtsubnet"
}
 
variable "nsg_name" {
  description = "The name of the Network Security Group."
  type        = string
  default     = "fmkbdtnsg"
}
 
# variable "app_service_name" {
 # description = "The name of the App Service for Azure Functions."
 # type        = string
 # default     = "fmkbdtappservice"
# }
 
variable "private_link_name" {
  description = "The name of the Private Link."
  type        = string
  default     = "fmkbdtplink"
}
