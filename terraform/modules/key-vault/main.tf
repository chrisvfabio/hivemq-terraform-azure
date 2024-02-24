resource "azurerm_key_vault" "vault" {
  name                        = var.key_vault_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
    ]
  }
}

resource "azurerm_key_vault_secret" "secret" {
  for_each     = var.secrets
  name         = each.value.name
  value        = each.value.value
  key_vault_id = azurerm_key_vault.vault.id
}
