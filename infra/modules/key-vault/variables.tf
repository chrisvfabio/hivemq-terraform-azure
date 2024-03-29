variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "secrets" {
  type = map(object({
    name  = string
    value = string
  }))
}