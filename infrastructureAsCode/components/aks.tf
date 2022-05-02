resource "azurerm_kubernetes_cluster" "k8scluster" {
  name                = "${var.labname}aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  dns_prefix          = "${var.labname}dns"
  kubernetes_version  = var.k8sVersion
  
  default_node_pool {
    name            = "${var.labname}pool"
    node_count      = var.nodecount
    vm_size         = var.vmSizeAks
    max_pods        = 130
    os_disk_size_gb = 100
    node_labels = {
      "sysbox-install" = "yes" # labels all nodes for the sysbox daemonset
    }
  }

  service_principal {
    client_id     = var.clientid
    client_secret = var.clientsecret
  }

  network_profile {
    network_plugin = "kubenet"
    load_balancer_sku = "Standard"
  }
  
  role_based_access_control {
    enabled = true
  }
}
