// This will output the public IP of the VM
output "ip" {
  value = azurerm_public_ip.ip.ip_address
}

// Displaying the SSH key
output "tls_private_key" {
  value = tls_private_key.ssh.private_key_pem
}
