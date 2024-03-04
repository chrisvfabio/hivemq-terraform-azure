# HiveMQ + MongoDB + Azure

This repo will walk you through how to:

- Deploy HiveMQ with the File RBAC Extension on Azure Container Apps, with public TCP ingress enabled and access restrictions.
- Deploy MongoDB on an Azure Virtual Machine with a data disk attached.
- Test the connectivity between the HiveMQ broker and the MongoDB instance within the same virtual network.

# Steps

## 0. Prepare Infrastructure Variables/Configuration

Located under `./environments/dev.tfvars` are the variables that will be used to deploy the infrastructure. Ensure you have reveiwed and updated the variables to match your desired configuration.

| Variable | Description |
| --- | --- |
| `subscription_id` | The Azure Subscription ID |
| `tenant_slug` | The slug/name of the client/tenant/project |
| `tenant_environment` | The environment of the tenant (e.g. dev, test, prod) |
| `tenant_region` | The Azure region to deploy the infrastructure |
| `tenant_tags` | Tags to apply to the resources |
| `vnet_address_space` | The CIDR block for the virtual network |
| `containers_subnet_name` | The name of the subnet for the Azure Container Apps |
| `containers_subnet_address_space` | The CIDR block for the Azure Container Apps subnet |
| `mongodb_subnet_name` | The name of the subnet for the Azure VM running MongoDB |
| `mongodb_subnet_address_space` | The CIDR block for the MongoDB subnet |
| `allowed_ips` | The IP addresses that are allowed to connect to the MongoDB instance and the Azure Container Apps instance |

## 1. Deploying the Infrastructure

Change directory into the `infrastructure` directory.

```bash
cd infra
```

Initialize the OpenTofu project.

```bash
tofu init
```

Run the `plan` command to see the changes that will be made to the infrastructure.

```bash
tofu plan -var-file ./environmnets/datainc/dev.tfvars
```

Run the `apply` command with the desired variables file to deploy the infrastructure.

```bash
tofu apply -var-file ./environmnets/datainc/dev.tfvars
```

## 2. Deploying MongoDB onto Azure VM

If using the auto-generated SSH password, you'll need to find the value in Azure Key Vault.

```bash
az keyvault secret show --vault-name datainc-dev --name mongodb-admin-password --query value --output tsv
```

Connect to the Azure VM using SSH.

```bash
ssh <username>@<hostname>

# Example:
# ssh mongodb-admin@mongodb-vm-01-lh4u4yygolcwk.australiaeast.cloudapp.azure.com
```

Deploy the mongo:7.0 container.

```bash
docker run -d --restart on-failure -p 27017:27017 --name mongodb -v /opt/data/mongo:/data/db mongo:7.0 --auth 
```

`/opt/data/mongo` - The Azure Data Disk is mounted to this directory, which is then mounted to the `/data/db` directory inside the mongo container.

`--auth` - this flag enables authentication for the MongoDB instance. Remove this flag to disable auth.

<br>

Open a shell to the MongoDB container to create a user with root role.

```bash
docker exec -it mongodb /bin/mongosh
```

Run the following commands to create a user with root role.
```bash
use admin

# Create a user with root role - use a better password
db.createUser({user: "root", pwd: "supersecret", roles: ["root"]})
```

Exit the mongo container shell and virtual machine. 


## 3. Deploying the HiveMQ Broker to Azure Container Apps

Log in to the Azure Container Registry to push the image.

```bash
az acr login --name dataincdevacr
```

Change directory into the `hivemq-broker` directory.

```bash
cd hivemq-broker
```

Build the Docker image.

```bash
docker build -t dataincdevacr.azurecr.io/hivemq-broker:latest .
```

Push the Docker image to the Azure Container Registry.

```bash
docker push dataincdevacr.azurecr.io/hivemq-broker:latest
```

## 4. Testing Connectivity


### Testing HiveMQ Broker externally

Fetch the Public DNS of the Azure Container Apps instance.

```bash
az containerapp ingress show --name hivemq-broker --resource-group rg-datainc-dev --output json | jq -r '.fqdn'
```

Run the hivemq/mqtt-cli container to test the connectivity to the HiveMQ broker.

```bash
docker run hivemq/mqtt-cli test \ 
  -h hivemq-broker--50xng8o.victoriousbeach-e8313d1b.australiaeast.azurecontainerapps.io \ 
  -p 1883 \ 
  -u user1 \ 
  -pw pass1
```

### Testing HiveMQ Listener Connectivity to MongoDB

For this test, we want to verify our container workload running in Azure Container Apps can connect to our MongoDB instance running on an Azure VM. 

Each of these applications are avilable under the same virtual network, so we can use the private IP address of the MongoDB instance to connect to it.

<br>

Find the private IP address of the MongoDB instance.

```bash
az vm show --name datainc-dev-vm --resource-group  rg-datainc-dev  --show-details --query privateIps --output tsv

# Output:
# 10.0.8.4
```

Next, let's open a shell into our Azure Container App instance to test the connectivity to the MongoDB instance.

Open a bash console session:

```bash
az containerapp exec --name hivemq-broker --resource-group rg-datainc-dev --command /bin/bash

# root@hivemq-broker--50xng8o-775cc5d95d-jq9ds:/opt/hivemq# 
```

Run the telnet command to test the connectivity to the MongoDB instance, using the private ip of the virutal machine and the port number of the MongoDB instance.

```bash
telnet 10.0.8.4 27017

# Output:
# root@hivemq-broker--50xng8o-775cc5d95d-jq9ds:/opt/hivemq# telnet 10.0.8.4 27017
# Trying 10.0.8.4...
# Connected to 10.0.8.4.
# Escape character is '^]'.
```
