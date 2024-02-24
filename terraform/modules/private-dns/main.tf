resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = var.domain
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_a_record" "private_dns_zone_entry" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 3600
  records             = [var.private_ip_address]
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link_hub" {
  name                  = "${var.domain}-hub-link"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
  registration_enabled  = false
}
