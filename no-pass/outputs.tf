// This will output the public IP of the VM
output "ip" {
  value = azurerm_public_ip.ip.ip_address
}
