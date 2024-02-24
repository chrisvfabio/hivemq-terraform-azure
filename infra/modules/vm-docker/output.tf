output "vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}

output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "internal_ip" {
  value = azurerm_network_interface.nic.private_ip_address
}
