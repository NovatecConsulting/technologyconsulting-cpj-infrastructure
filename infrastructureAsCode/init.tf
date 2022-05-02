# configure terraform to use an Azure Storage for sync all platform's state
terraform {
  backend "azurerm" {
    container_name       = "terraformstate"
  }
}

module "components" {
  source                  = "./components"
  labname                 = var.labname
  location                = var.location
  labNumberParticipants   = var.labNumberParticipants
  vmSizeAks               = var.vmSizeAks
  nodecount               = var.nodecount
  clientid                = var.clientid
  clientsecret            = var.clientsecret
  rsgcommon               = var.rsgcommon
  sshUserPw               = var.sshUserPw
  k8sVersion              = var.k8sVersion
}

# -------------------------
# as env-variables are use to pass information to the module,
# they are needed to be defined here as well
# inside the module, environmentVariables.tf is taking care of variables

variable "clientid" {
  # will be provided as environment variable.
}

variable "clientsecret" {
  # will be provided as environment variable.
}


variable "location" {
    # will be provided as environment variable.
}

variable "labname" {
    # will be provided as environment variable.
}

variable "labNumberParticipants" {
    # will be provided as environment variable.
}

variable "vmSizeAks" {
    # will be provided as environment variable.
}
variable "nodecount" {
    # will be provided as environment variable.
}

variable "rsgcommon" {
  # will be provided as environment variable.
}

variable "sshUserPw" {
  # will be provided as environment variable.
}

variable "k8sVersion" {
  # will be provided as environment variable.
}


provider "azurerm" {
    # will receive configration by environment variables
    #version = "2.32.0"
    features {}
}
