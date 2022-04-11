resource "azurerm_resource_group" "resourceGroup" {
        name      = var.labname
        location  = var.location
}