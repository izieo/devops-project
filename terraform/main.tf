#-------------------------
# Existing Resource Group
#-------------------------
data "azurerm_resource_group" "existing_rg" {
  name = var.resource_group_name
}
#-------------------------
# Azure Container Registry
#-------------------------
resource "azurerm_container_registry" "acr" {
  name                = "izieomodevopsacr"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  location            = data.azurerm_resource_group.existing_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

#-------------------------
# AKS Cluster
#-------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "devops-aks"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  dns_prefix          = "devopsaks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    Environment = "Dev"
  }
}


#-------------------------
# Output kubeconfig
#-------------------------

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}
