resource "azurerm_container_registry" "registry" {
  name                = replace("${var.project_name}acr", "/[^a-zA-Z0-9]/", "")
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_user_assigned_identity" "identity" {
  name                = "id-${var.project_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
}


resource "azurerm_role_assignment" "role_assignment" {
  scope                = azurerm_container_registry.registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}
