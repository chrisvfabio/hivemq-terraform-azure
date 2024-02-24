resource "azurerm_container_app_environment" "container_app_environment" {
  name                           = var.name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  internal_load_balancer_enabled = var.internal
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  zone_redundancy_enabled        = true
  log_analytics_workspace_id     = var.log_analytics_workspace_id
}
