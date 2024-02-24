
tenant_id          = "datainc"
tenant_environment = "dev"
tenant_region      = "australiaeast"
tenant_tags = {
  "owner"       = "datainc",
  "environment" = "dev",
}

vnet_address_space = "10.0.0.0/16"

containers_subnet_name          = "containers"
containers_subnet_address_space = "10.0.0.0/21"

mongodb_subnet_name          = "mongodb"
mongodb_subnet_address_space = "10.0.8.0/24"
