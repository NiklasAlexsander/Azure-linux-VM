// uncomment this block if you want to configure "remote state"
// - https://www.terraform.io/docs/state/remote.html
// - https://www.terraform.io/docs/backends/types/azurerm.html
terraform {
  backend "azurerm" {
    resource_group_name  = "tstate"
    storage_account_name = "tstate1234"
    container_name       = "tstate"
    key                  = "interview-task.tfstate"
  }
}
