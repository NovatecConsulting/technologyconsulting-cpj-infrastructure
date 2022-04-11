# resource "azurerm_storage_account" "pod_storage" {
#  account_replication_type  = "RAGRS"
#  account_tier              = "Standard"
#  account_kind              = "StorageV2"
#  location                  = var.location
#  name                      = "${var.labname}podstorage"
#  # resource_group_name       = azurerm_resource_group.resourceGroup.name TODO: Check warum in anderer Resource-Group
#  resource_group_name       = "MC_${var.labname}_${var.labname}aks_${var.location}"
#  enable_https_traffic_only = false
# }

# resource "kubernetes_secret" "pod_storage_secret" {
#  metadata {
#    name = "storage-secret"
#  }

#  data = {
#    azurestorageaccountname: base64encode(azurerm_storage_account.pod_storage.name)
#    azurestorageaccountkey: base64encode(azurerm_storage_account.pod_storage.primary_access_key)
#  }
# }