data "azurerm_virtual_network" "vnet" {
  name = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.rg.name
}
