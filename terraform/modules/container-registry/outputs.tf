output "identity_id" {
  value = azurerm_user_assigned_identity.identity.id
}

output "server_url" {
  value = azurerm_container_registry.registry.login_server
}

