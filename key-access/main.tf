
// Configure the azure provider.
// Feature block is required.
provider "azurerm" {
  version = "2.18.0"
  features {}
}

// The desired state of the resource.
// Using the join-function to create a single string with multiple variables.
// Did not find any other way to create a string containing interpolation and hyphens.
resource "azurerm_resource_group" "rg" {
  name     = "${var.tags.environment}-${var.myname}-rg"
  location = var.location
  tags     = var.tags
}

// Creating a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.tags.environment}-${var.myname}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

// Creating a subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.tags.environment}-${var.myname}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

// Creating a public IP
resource "azurerm_public_ip" "ip" {
  name                = "${var.tags.environment}-${var.myname}-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  tags                = var.tags
}

// creating Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.tags.environment}-${var.myname}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = var.allowed_port
    destination_port_range     = var.allowed_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

// Creating network interface (NIC)
resource "azurerm_network_interface" "nic" {
  name                = "${var.tags.environment}-${var.myname}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "nic-config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.ip.id
  }
}

// Creating an SSH key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Saving private key in a txt-file called "private_key.txt" in the working directory.
resource "local_file" "key" {
  filename = "private_key.txt"
  content  = tls_private_key.ssh.private_key_pem

  provisioner "local-exec" {
    command = var.local_executable_secure_key
  }
}

// Creating the Linux virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "${var.tags.environment}-${var.myname}-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_DS1_v2"
  tags                  = var.tags

  os_disk {
    name                 = "os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    //offer     = "UbuntuServer"
    offer   = "0001-com-ubuntu-server-focal"
    sku     = lookup(var.sku, var.location)
    version = "latest"
  }

  computer_name  = "vm"
  admin_username = var.admin_username
  //admin_password = var.admin_password
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }
}

locals {
  // A for-loop going over each element in the allowed_ip_address list and grants them 
  // access to port 22 (SSH): 'ufw allow from IP to any port PORTNR'
  // Creates a long command passed to the VM in the 'azure_remote_exe'-resource.
  allowed_ip_command = join(" ", [for address in var.allowed_ip_addresses : format("; ufw allow from %s to any port ${var.allowed_port}", address)])
}

// Installing 'cowsay' to VM with azure vm extension
// More info at: https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux
resource "azurerm_virtual_machine_extension" "azure_remote_exe" {
  name                 = azurerm_linux_virtual_machine.vm.computer_name
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
  {
    "commandToExecute": " ${var.linux_cowsay_installation_command} ; sudo -i ; ufw enable && ufw default deny incoming ${local.allowed_ip_command}"
  }
  SETTINGS
}
