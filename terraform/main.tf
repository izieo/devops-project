
#-------------------------
# Resource Group
#-------------------------
resource "azurerm_resource_group" "main" {
  name     = "devops-rg"
  location = "East US"
}

#-------------------------
# Azure Container Registry
#-------------------------
resource "azurerm_container_registry" "acr" {
  name                = "izieomodevopsacr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

#-------------------------
# AKS Cluster
#-------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "devops-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
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
# Grant AKS access to ACR
#-------------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
