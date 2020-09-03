location = "westeurope"
myname = "test"
//allowed_ip_addresses = ["x.x.x.x","x.x.x.x"]
allowed_port = "22"
linux_cowsay_installation_command = "until sudo apt-get update -y; do sleep 2; done ; sudo apt-get install -y cowsay"

tags = {
    environment = "dev"
}
