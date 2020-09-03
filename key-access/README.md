# Creating a linux (Ubuntu) VM with terraform using a ssh key deployed in the Azure cloud!
This is a guide on how to create a linux virtual machine using terraform and the files included. In this 'solution' we are going to use a ssh-key-pair to authenticate the login. This is done by creating a ssh public and private key, giving the public key to the VM and the private key is saved as a file and echoed to the user.

The latest version of Ubuntu is being used (Ubuntu 20.04-LTS).

(TO CHANGE THE IP-ADDRESSES THAT GETS ACCESS TO THE VM, PLEASE EDIT THE LIST-VARIABLE 'allowed_ip_addresses' LOCATED IN THE 'terraform.tfvars'. I HAVE REMOVED THE IP'S FOR SECURITY REASONS)

# ABOUT THE TESTING
Everything is tested on a machine running macOS Catalina version 10.15.5. Cannot guarantee that the scripts included will run on anything else.
#### About the key-pair
When creating a key-pair inside of the 'main.tf' the key gets saved inside of a file called 'private_key.txt'. Then a script inside of 'main.tf' will activate which 'seals' the 'private_key.txt' so it will be accepted as a ssh-key! So for the sake of convenience I have included a small local-exec to do this 'securing' of the file. It's nothing more than a 'chmod 600 private_key.txt'.

# Structure

| Filename             | Explanation                                                         |
| -------------------- | ------------------------------------------------------------------- |
| main.tf              | The main terraform-file for the creation of resources.              |
| variables.tf         | Contains the 'global'-input-variables used in 'main.tf'             |
| terraform.tfvars     | Giving most of the input-variables a value                          |
| outputs.tf           | Some outputs to be seen in the terminal after deployment-completion |
| backend.tf           | The backend connecting the remote state to azure storage            |
| configure_storage.sh | Script for creating azure storage for remote-state use              |
| private_key.txt      | Contains a generated RSA private key to match VM. Will be created when deploying with terraform apply.     
| README.md | Documentation on the project |

# Prerequisites
  - Terraform installed.
  - An Azure subscription.
  - Azure CLI installed.
  - That you are logged in to your Azure account with the subscription through AZ in a terminal.

# Local state save or remote state?
### Remote state
If you want to use a remote state by using azure storage with terraform you first need to create a resource-group and a storage including a container. I have therefore included a script which takes care of this. The only Prerquisite for this script to work is that you have logged in to your azure account with 'az cli' in a terminal. To run the script all you need to do is to locate the folder containing the script and run it like so:

```
$ sh configure_storage_account.sh
```

This will create the resource group, storage, and container with the name:
  - resource_group_name = 'tstate'
  - storage_account_name = 'tstate1234'
  - container_name = 'tstate'

All of these names will be echoed for the user to see.

REMEMBER TO DELETE THE STORAGE AFTER USE! This could be done with AZ CLI as follows:

```
$ az group delete --name tstate
```

You need to run 'terraform init' with the flag '-reconfigure' if you want to save the terraform state in a new storage.

### Local state save
To use a local state save you need to comment out or delete the 'backend.tf' file, and there is no need to run the 'configure_storage_account.sh'. Since the backend was never run/used, the state-files should be saved in the same directory.

# HOW TO RUN
To create and deploy a linux VM in azure the only thing you need to do is to follow these simple steps:

**Step 1:** Clone the project
**Step 2:** Open the terminal and move to the cloned project-folders directory '/key-access'
**Step 3:** Run terraform init

```
$ terraform init
```

**Step 4:** Run terraform plan to see the estimated execution plan (run with the flag out to secure that the right plan is getting 'applied'). You will be asked to input a username and public-ip-addresses of your choice (THIS USERNAME WILL BE USED TO SSH TO THE VM. THE PUBLIC-IP'S GIVEN ARE GRANTED ACCESS TO THE VM).
**It is really important that the format of the public IP's given is a list of strings, ex: ["x.x.x.x", "x.x.x.x", ...etc]**
The list can be as lagre as you want.

```
$ terraform plan
```

OR

```
$ terraform plan -out 'terraform_plan'
```

**Step 5:** Run "terraform apply" or "terraform apply 'terraform_plan'"

```
$ terraform apply
```

The apply command will run all the files assosiated with terraform 'filename.**tf**'.

##### And there you go!
You have just created a virtual machine running linux (ubuntu) with preinstalled cowsay in the azure cloud! To access the newly created VM, follow the steps below.

# How to access the VM
To access the VM all you have to do is a ssh into the public-ip-address that's been given. When the VM got deployed by terraform the public-IP got echoed in the terminal above the private-key (The private key is only echoed to show what was saved in the 'private_key.txt'). Here's an example of how to access the VM:

```
$ ssh -i private_key.txt <username>@<PUBLIC-IP>
```

The '-i' flag will allow us to add an identity-file, this would be our 'private_key.txt'-file.
You may be asked if you want to trust this ssh, type 'yes' if you trust the connection to the VM.

# Make cowsay say 'Cloud Platform <3 IaC'
To run cowsay all you need to do is to connect to the VM. Once inside you move to the games directory and run cowsay:

```
$ cd /usr/games
```

```
/usr/games$ ./cowsay 'Cloud Platform <3 IaC'
```

Which returns:
```
 __________________
< Cloud Platform <3 IaC >
 ------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

### Do remember to 'destroy' the VM when done!
You can destroy the VM by typing the following in your terminal:

```
$ terraform destroy
```

# How did cowsay get installed and how did connections get blocked to the VM?
I solved this by running a 'script' on the VM after deployment. To install cowsay I run:

```
$ until sudo apt-get update -y; do sleep 2; done ; sudo apt-get install -y cowsay
```

The 'until' command let's the code get run until it it succeeds. When the update is done, cowsay is installed. This command is saved in a variable called 'linux_cowsay_installation_command'.

To block all IP's and only allow a set on port 22, I used ufw (Uncomplicated Firewall) to create rules. But before the rule-creation, I need to create the command/string which is saved in a 'locals' variable called 'allowed_ip_command' as follows:

```
allowed_ip_command = join(" ", [for address in var.allowed_ip_addresses : format("; ufw allow from %s to any port ${var.allowed_port}", address)])
```

This will look something like this:

```
"; ufw allow from IP-ADDRESS to any port PORTNUMBER ; ufw allow from IP-ADDRESS to any port PORTNUMBER" ...etc
```

To pass these commands to the linux VM I use a resource called azurerm_virtual_machine_extension which lets us pass commands through  'settings' = 'commandToExecute':

```
  settings = <<SETTINGS
  {
    "commandToExecute": " ${var.linux_cowsay_installation_command} ; sudo -i ; ufw enable && ufw default deny incoming ${local.allowed_ip_command}"
  }
  SETTINGS
```

the 'sudo -i' is to ensure that the rules is given to the whole VM, and not to just a single user.
