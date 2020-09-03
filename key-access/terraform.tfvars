location = "westeurope"
myname = "test"
//allowed_ip_addresses = ["x.x.x.x","x.x.x.x"]
allowed_port = "22"
local_executable_secure_key = "chmod 600 private_key.txt"
linux_cowsay_installation_command = "until sudo apt-get update -y; do sleep 2; done ; sudo apt-get install -y cowsay"
tags = {
    environment = "dev"
}
