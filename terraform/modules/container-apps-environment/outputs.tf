output "environment_id" {
  value = azurerm_container_app_environment.container_app_environment.id
}

output "default_domain" {
  value = azurerm_container_app_environment.container_app_environment.default_domain
}

output "static_ip_address" {
  value = azurerm_container_app_environment.container_app_environment.static_ip_address
}

output "environment_name" {
  value = azurerm_container_app_environment.container_app_environment.name
}

output "resource_group_name" {
  value = azurerm_container_app_environment.container_app_environment.resource_group_name
}