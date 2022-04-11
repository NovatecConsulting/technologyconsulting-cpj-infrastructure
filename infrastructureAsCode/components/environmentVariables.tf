data "azurerm_client_config" "current" {
    # lookup for azure resource manager's config
}

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

variable "participantPodName" {
  type = string
  default = "participant-pod-statefulset"
}

variable "participantPodLabel" {
  type = string
  default = "participant-pod"
}

variable "participantPodNamespaceName" {
  type = string
  default = "user"
}

variable "participantPodDockerUser" {
  type = string
  default = "novatec"
}
variable "sshUserPw" {
  # will be provided as environment variable.
}