subscription_id    = "829b2115-589a-47b2-97a0-7c214012d2d8"
tenant_slug        = "datainc"
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

allowed_ips = [
  "38.69.183.222"
]
