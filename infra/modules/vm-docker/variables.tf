variable "name" {
  description = "The name prefix for all resources."
  type        = string
}

variable "location" {
  description = "Location for all resources."
  type        = string
}

variable "vm_size" {
  description = "The size of the VM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "ubuntu_os_version" {
  description = "The Ubuntu version for the VM."
  type        = string
  default     = "Ubuntu-2204"
}

variable "admin_username" {
  description = "Username for the Virtual Machine."
  type        = string
}

variable "authentication_type" {
  description = "Type of authentication to use on the Virtual Machine."
  type        = string
  default     = "password"
}

variable "admin_password_or_key" {
  description = "SSH Key or password for the Virtual Machine."
  type        = string
}

variable "subnet_id" {
  description = "The subnet to use for the Virtual Machine."
  type        = string
}

variable "allowed_ip_addresses" {
  description = "List of allowed IP addresses to access the Virtual Machine."
  type        = list(string)
  default     = []
}

variable "additional_security_rules" {
  description = "Additional security rules to apply to the Network Security Group."
  type        = any
  default     = []
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "vm_dns_label" {
  description = "The DNS label for the VM. Must be a unique name. Creates the domain as <dns-label>.australiaeast.cloudapp.azure.com"
  type        = string
  default     = null
}
