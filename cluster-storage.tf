
resource "azurerm_storage_account" "log-storage-acct" {
    name                     = "${var.app}${var.env}log"
    resource_group_name      = "${azurerm_resource_group.cluster-rg.name}"
    location                 = "${azurerm_resource_group.cluster-rg.location}"
    account_tier             = "Standard"
    account_replication_type = "LRS"

    tags = "${local.default_tags}"
}

resource "azurerm_storage_account" "diag-storage-acct" {
    name                     = "${var.app}${var.env}diag"
    resource_group_name      = "${azurerm_resource_group.cluster-rg.name}"
    location                 = "${azurerm_resource_group.cluster-rg.location}"
    account_tier             = "Standard"
    account_replication_type = "LRS"

    tags = "${local.default_tags}"
}
