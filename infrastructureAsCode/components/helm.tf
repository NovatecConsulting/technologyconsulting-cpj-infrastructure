#With this provider you can deploy helm charts in the new created aks 
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.k8scluster.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.k8scluster.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.k8scluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8scluster.kube_config.0.cluster_ca_certificate)
    load_config_file       = "false"
  }
  debug = "true"
}

resource "helm_release" "sysbox" {
  depends_on = [azurerm_kubernetes_cluster.k8scluster]
  name       = "sysbox"
  chart      = "./helm/sysbox"
}

  resource "helm_release" "ingress-nginx" {
    depends_on = [azurerm_kubernetes_cluster.k8scluster]
    name       = "ingress-nginx"
    #version    = "2.11.2"
    repository = "https://kubernetes.github.io/ingress-nginx"
    chart      = "ingress-nginx"
    namespace  = "ingress-nginx"

    set  {
          name = "controller.admissionWebhooks.enabled"
          value = "false"
      }

  }

  resource "helm_release" "traefik" {
    depends_on = [azurerm_kubernetes_cluster.k8scluster]
    name       = "traefik"
    repository = "https://helm.traefik.io/traefik"
    chart      = "traefik"
    force_update  = "true"
    namespace  = "traefik-v2"

    set  {
      name = "ingressClass.enabled"
      value = "true"
    }

    set  {
      name = "providers.kubernetesIngress.publishedService.enabled"
      value = "true"
    }

    set  {
      type = "string"
      name = "additionalArguments"
      value = "{--providers.kubernetesingress.ingressclass=traefik,--global.sendanonymoususage=false,--log.level=DEBUG}"
    }

  }

  resource "null_resource" "gitclonepostgresoperator" {

    triggers = {
      build_number = timestamp()
    }
    #bugfix: there are some yaml errors in master branch. checkout tag
    provisioner "local-exec" {
      command = "git clone https://github.com/zalando/postgres-operator /tmp/postgres-operatorgit && sleep 60 && ls -a /tmp/postgres-operatorgit/charts/ && cd /tmp/postgres-operatorgit && git checkout v1.5.0"
    }
  }

  resource "helm_release" "postgres-operator" {
    depends_on = [null_resource.gitclonepostgresoperator]
    name       = "postgres-operator"
    chart      = "/tmp/postgres-operatorgit/charts/postgres-operator"
    namespace  = "operators"
    timeout    = "500"
  }


resource "helm_release" "participants" {
  depends_on = [azurerm_kubernetes_cluster.k8scluster]
  name       = "participants"
  chart      = "./helm/participants"
  namespace  = "default"
  wait       = true
  timeout    = 2400

  set {
    name  = "namespace.name"
    value = var.participantPodNamespaceName
  }


  set {
    name  = "participant.name"
    value = var.participantPodName
  }

  set {
    name  = "participant.replicas"
    value = var.labNumberParticipants
  }

  set {
    name  = "participant.label"
    value = var.participantPodLabel
  }
}