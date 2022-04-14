resource "azurerm_storage_account" "static_website" {
  account_replication_type  = "RAGRS"
  account_tier              = "Standard"
  account_kind              = "StorageV2"
  location                  = var.location
  name                      = "${var.labname}materials"
  resource_group_name       = azurerm_resource_group.resourceGroup.name
  enable_https_traffic_only = true

  allow_blob_public_access = true
  static_website {
    index_document = "index.html"
    error_404_document = "error.html"
  }

}