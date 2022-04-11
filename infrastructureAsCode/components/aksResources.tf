provider "kubernetes" {
  host = azurerm_kubernetes_cluster.k8scluster.kube_config.0.host
  client_certificate = base64decode(azurerm_kubernetes_cluster.k8scluster.kube_config.0.client_certificate)
  client_key = base64decode(azurerm_kubernetes_cluster.k8scluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8scluster.kube_config.0.cluster_ca_certificate)
  load_config_file = "false"
}

resource "kubernetes_namespace" "nsforoperators" {
  depends_on = [azurerm_kubernetes_cluster.k8scluster]
  timeouts {
    delete = "2h"
  }
  metadata {
    name = "operators"
  }

}

resource "kubernetes_namespace" "nsfornginx" {
  depends_on = [azurerm_kubernetes_cluster.k8scluster]
  timeouts {
    delete = "2h"
  }
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "nsfortraefik" {
  depends_on = [azurerm_kubernetes_cluster.k8scluster]
  timeouts {
    delete = "2h"
  }
  metadata {
    name = "traefik-v2"
  }
}