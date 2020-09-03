// the "{}" means that the variable is required, but no
// specific type is required, therefore the type of the
// variable will be determined by the input value.

// Location of the server where the VM is hosted on Azure.
variable "location" {
  type        = string
  description = "Location of where the VM should be placed."
}

// Name of the creator
variable "myname" {
  type        = string
  description = "Name of the terraform-user."
}

// Admin username for the VM
variable "admin_username" {
  type        = string
  description = "Username of the administrator for the VM."
}

// Public-IP's to have access to the VM
variable "allowed_ip_addresses" {
  type = list(string)
}

// Port to allow Public-IP's enter (SSH port 22)
variable "allowed_port" {
  type = string
}

// Command passed to VM for installation of cowsay
variable "linux_cowsay_installation_command" {
  type        = string
  description = "Command to be passed to VM for installation of cowsay."
}

// Tags used on resources
variable "tags" {
  type = map(string)
}

// Command locally executed for 'securing' private-key for SSH-use
variable "local_executable_secure_key" {
  type        = string
  description = "Unix command to secure private key for usage in SSH to VM"
}

// sku -> Stock-Keeping Unit
// Do not actually need to declare type when creating map, but it's
// a nice thing to include for 'clarity' when reading the code.
// LTS -> Long Term Support
// 20.04-LTS seems to be the latest version
variable "sku" {
  type = map(string)

  default = {
    //westeurope = "18.04-LTS"
    westeurope = "20_04-lts"
  }
}
