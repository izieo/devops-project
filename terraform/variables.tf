variable "resource_group_name" {
  description = "The name of the existing Azure resource group"
  type        = string
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "client_id" {
  type        = string
  description = "Azure client ID (App Registration)"
}

variable "client_secret" {
  type        = string
  description = "Azure client secret (App Registration)"
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID"
}
