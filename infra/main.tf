locals {
  global_tags = {
    tenant      = var.tenant_id
    environment = var.tenant_environment
  }

  allowed_ips = var.allowed_ips
}

resource "azurerm_resource_group" "tenant_rg" {
  name     = "rg-${var.tenant_id}-${var.tenant_environment}"
  location = var.tenant_region
  tags     = merge(local.global_tags, var.tenant_tags, {})
}

module "network" {
  source                  = "Azure/network/azurerm"
  resource_group_name     = azurerm_resource_group.tenant_rg.name
  resource_group_location = azurerm_resource_group.tenant_rg.location
  address_spaces          = [var.vnet_address_space]

  ## Uncomment!!
  # vnet_name = "${var.tenant_id}-${var.tenant_environment}-vnet"

  subnet_prefixes = [var.containers_subnet_address_space, var.mongodb_subnet_address_space]
  subnet_names    = [var.containers_subnet_name, var.mongodb_subnet_name]
  subnet_enforce_private_link_endpoint_network_policies = {
    "${var.containers_subnet_name}" = false
    "${var.mongodb_subnet_name}"    = false
  }

  use_for_each = true

  tags = merge(local.global_tags, var.tenant_tags, {})

  depends_on = [azurerm_resource_group.tenant_rg]
}

module "container_registry" {
  source              = "./modules/container-registry"
  resource_group_name = azurerm_resource_group.tenant_rg.name
  location            = var.tenant_region
  project_name        = "${var.tenant_id}-${var.tenant_environment}"
  depends_on          = [module.network, azurerm_resource_group.tenant_rg]
}

resource "random_password" "mongodb_admin_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

module "container_app_environment" {
  source                     = "./modules/container-apps-environment"
  name                       = "${var.tenant_id}-${var.tenant_environment}"
  location                   = var.tenant_region
  resource_group_name        = azurerm_resource_group.tenant_rg.name
  internal                   = false # Allow 
  infrastructure_subnet_id   = module.network.vnet_subnets[0]
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on                 = [module.network, azurerm_resource_group.tenant_rg]
}

# module "private_dns" {
#   source               = "./modules/private-dns"
#   resource_group_name  = azurerm_resource_group.tenant_rg.name
#   virtual_network_name = module.network.vnet_name
#   private_ip_address   = module.mongodb.internal_ip
#   domain               = module.container_app_environment.default_domain

#   depends_on = [azurerm_resource_group.tenant_rg]
# }

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.tenant_id}-${var.tenant_environment}-law"
  resource_group_name = azurerm_resource_group.tenant_rg.name
  location            = azurerm_resource_group.tenant_rg.location
  retention_in_days   = 30
  sku                 = "PerGB2018"

}

module "container_apps" {
  source              = "./modules/container-apps"
  resource_group_name = azurerm_resource_group.tenant_rg.name
  location            = azurerm_resource_group.tenant_rg.location

  container_app_environment_name = module.container_app_environment.environment_name
  container_app_environment = {
    name                = module.container_app_environment.environment_name
    resource_group_name = azurerm_resource_group.tenant_rg.name
  }

  container_apps = {
    "hivemq-broker" = {
      name          = "hivemq-broker"
      revision_mode = "Single"

      identity = {
        identity_ids = [module.container_registry.identity_id]
        type         = "UserAssigned"
      }

      template = {
        min_replicas = 1
        max_replicas = 3

        containers = [
          {
            name   = "hivemq-broker"
            image  = "${module.container_registry.server_url}/hivemq-broker:latest"
            cpu    = 0.25
            memory = "0.5Gi"
          }
        ]
      }
      ingress = {
        target_port                = 1883
        allow_insecure_connections = false
        external_enabled           = true
        transport                  = "tcp"
        traffic_weight = {
          percentage      = 100
          latest_revision = true
        }

        ip_security_restrictions = concat([
          {
            name             = "MongoDBVirtualMachine"
            action           = "Allow"
            ip_address_range = "${module.mongodb.public_ip_address}/32"
          }
          ], [
          for ip in local.allowed_ips : {
            name             = "AllowedIPAddresses"
            action           = "Allow"
            ip_address_range = "${ip}/32"
          }
        ])
      }
      registry = [
        {
          server   = module.container_registry.server_url
          identity = module.container_registry.identity_id
        }
      ]
    }

    "hivemq-listener-node" = {
      name          = "hivemq-listener-node"
      revision_mode = "Single"

      identity = {
        identity_ids = [module.container_registry.identity_id]
        type         = "UserAssigned"
      }

      template = {
        min_replicas = 1
        max_replicas = 3

        containers = [
          {
            name   = "hivemq-listener-node"
            image  = "${module.container_registry.server_url}/hivemq-listener-node:latest"
            cpu    = 0.25
            memory = "0.5Gi"
            env = [
              {
                name  = "HIVEMQ_BROKER_HOSTNAME"
                value = "hivemq-broker"
              },
              {
                name  = "HIVEMQ_BROKER_TOPIC"
                value = "test"
              },
              {
                name  = "MONGO_HOSTNAME"
                value = "10.0.8.4"
              }
            ]
          }
        ]
      }
      registry = [
        {
          server   = module.container_registry.server_url
          identity = module.container_registry.identity_id
        }
      ]
    }
  }
  log_analytics_workspace = {
    id = azurerm_log_analytics_workspace.law.id
  }

  depends_on = [ module.container_app_environment ]
}


module "key_vault" {
  source = "./modules/key-vault"

  key_vault_name      = "${var.tenant_id}-${var.tenant_environment}"
  resource_group_name = azurerm_resource_group.tenant_rg.name
  location            = azurerm_resource_group.tenant_rg.location

  secrets = {
    "mongodb-admin-password" = {
      name  = "mongodb-admin-password"
      value = random_password.mongodb_admin_password.result
    }
  }
  depends_on = [azurerm_resource_group.tenant_rg]
}

module "mongodb" {
  source                = "./modules/vm-docker"
  resource_group_name   = azurerm_resource_group.tenant_rg.name
  name                  = "${var.tenant_id}-${var.tenant_environment}"
  location              = var.tenant_region
  vm_size               = "Standard_D2s_v3"
  ubuntu_os_version     = "Ubuntu-2204"
  admin_username        = "admin-mdb"
  authentication_type   = "password"
  admin_password_or_key = random_password.mongodb_admin_password.result
  subnet_id             = module.network.vnet_subnets[1]

  allowed_ip_addresses = concat([module.container_app_environment.static_ip_address], local.allowed_ips)

  additional_security_rules = [
    {
      name                       = "AllowMongoDB"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "27017"
      source_address_prefixes    = concat([module.container_app_environment.static_ip_address], local.allowed_ips)
      destination_address_prefix = "*"
    }
  ]

  depends_on = [module.network, azurerm_resource_group.tenant_rg]
}


# delegated subnet?
