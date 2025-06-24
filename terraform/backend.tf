#-------------------------
# Backend Storage Account
#-------------------------

terraform {
  backend "azurerm" {
    resource_group_name  = "devops-rg"
    storage_account_name = "devopstfstateacct4005" 
    container_name       = "tfstate"
    key                  = "devops.terraform.tfstate"
  }
}