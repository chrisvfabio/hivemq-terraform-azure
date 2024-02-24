locals {
  vm_name = "${var.name}-vm"
}

resource "random_string" "random_chars" {
  count   = var.vm_dns_label == null ? 1 : 0
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = var.vm_dns_label == null ? "${local.vm_name}-${random_string.random_chars[0].result}" : var.vm_dns_label
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_ip_addresses
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.additional_security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefixes    = security_rule.value.source_address_prefixes
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on                = [azurerm_network_security_group.nsg]
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = local.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = var.ubuntu_os_version == "Ubuntu-2004" ? "0001-com-ubuntu-server-focal" : "0001-com-ubuntu-server-jammy"
    sku       = var.ubuntu_os_version == "Ubuntu-2004" ? "20_04-lts-gen2" : "22_04-lts-gen2"
    version   = "latest"
  }

  admin_password = var.authentication_type == "password" ? var.admin_password_or_key : null

  dynamic "admin_ssh_key" {
    for_each = var.authentication_type == "sshPublicKey" ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.admin_password_or_key
    }
  }

  disable_password_authentication = var.authentication_type == "sshPublicKey"

  custom_data = base64encode(file("./modules/vm-docker/cloud-init.yaml"))
}
