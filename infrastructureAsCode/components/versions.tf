terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.32.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "1.3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "1.13.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.0.0"
    }
  }
  required_version = ">= 1.1.8"
}