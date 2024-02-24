variable "tenant_id" {
  description = "Unique identifier for the tenant"
  type        = string
}

variable "tenant_environment" {
  description = "The environment for the tenant (dev, staging, prod)"
  type        = string
}

variable "tenant_region" {
  description = "The region where the tenant resources will be deployed"
  type        = string
}

variable "tenant_tags" {
  description = "Tags specific to the tenant"
  type        = map(string)
  default     = {}

}

variable "vnet_address_space" {
  type = string
}

variable "containers_subnet_name" {
  type = string
}

variable "containers_subnet_address_space" {
  type = string
}

variable "mongodb_subnet_name" {
  type = string
}

variable "mongodb_subnet_address_space" {

}

variable "allowed_ips" {
  type = list(string)
  description = "List of IP addresses that are allowed to access the resources in the tenant"
}