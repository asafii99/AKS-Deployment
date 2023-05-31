##
# Set and Configure the Azure Provider and the backend for the Terraform state file
##
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "$(az_version)"
    }
  }
  backend "azurerm" {
      resource_group_name  = "$(aks_rg_name)"
      storage_account_name = "$(az_storage_name)"
      container_name       = "tfstate"
      key                  = "terraform.tfstate"
  }
}

##
# Configure the Azure Provider
##
provider "azurerm" {
  features {}
}

##
# Retrieve the existing resource group for the azure resources
##
data "azurerm_resource_group" "my_rg" {
  name = "$(aks_rg_name)"
}

##
# Create a Log Analytics Solution
##
resource "random_id" "workspace" {
  keepers = {
    # Generate a new id each time we switch to a new resource group
    group_name = data.azurerm_resource_group.my_rg.name
  }

  byte_length = 8

}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "k8s-workspace-${random_id.workspace.hex}"
  location            = data.azurerm_resource_group.my_rg.location
  resource_group_name = data.azurerm_resource_group.my_rg.name
}

resource "azurerm_log_analytics_solution" "logs" {
  solution_name         = "ContainerInsights"
  location              = data.azurerm_resource_group.my_rg.location
  resource_group_name   = data.azurerm_resource_group.my_rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.logs.id
  workspace_name        = azurerm_log_analytics_workspace.logs.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

##
# Create Vnet and subnet for the AKS cluster
##
resource "azurerm_virtual_network" "vnet_cluster" {
  name                = "vnet-aks-demo"
  location            = data.azurerm_resource_group.my_rg.location
  resource_group_name = data.azurerm_resource_group.my_rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "snet_cluster" {
  name                 = "snet-aks-demo"
  resource_group_name  = data.azurerm_resource_group.my_rg.name
  virtual_network_name = azurerm_virtual_network.vnet_cluster.name
  address_prefixes     = ["10.1.0.0/24"]
}

##
# Create the AKS Cluster
##
resource "azurerm_kubernetes_cluster" "my_aks" {
  name                = "$(aks_cluster_name)"
  location            = data.azurerm_resource_group.my_rg.location
  resource_group_name = data.azurerm_resource_group.my_rg.name
  dns_prefix          = "aks-cluster"

  # Improve security using Azure AD, K8s roles and rolebindings. 
  # Each Azure AD user can gets his personal kubeconfig and permissions managed through AD Groups and Rolebindings
  role_based_access_control_enabled = true
  
  # Enable Monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  }
  # To prevent CIDR collition with the 10.0.0.0/16 Vnet
  network_profile {
    network_plugin     = "kubenet"
    docker_bridge_cidr = "192.167.0.1/16"
    dns_service_ip     = "192.168.1.1"
    service_cidr       = "192.168.0.0/16"
    pod_cidr           = "172.16.0.0/22"
  }

  default_node_pool {
    name                    = "default"
    node_count              = 1
    vm_size                 = "Standard_DS2_v2"
    zones                   = [1, 2, 3]
    vnet_subnet_id          = azurerm_subnet.snet_cluster.id
  }

  service_principal {
    client_id     = "$(client_id)"
    client_secret = "$(client_secret)"
  }
}