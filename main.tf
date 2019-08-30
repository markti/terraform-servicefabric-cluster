
resource "random_string" "random" {
  length = 3
  upper   = false
  lower   = true
  number  = false
  special = false
}

resource "azurerm_resource_group" "cluster-rg" {

    name     = "${var.app}-cluster-${var.env}"
    location = "East US"

}

locals {

    cluster_name = "${var.app}-cluster-${var.env}"
    default_tags = {
        resourceType = "Service Fabric",
        clusterName = "${local.cluster_name}"
    }
    port_fabricTcpGateway = "19000"
    port_fabricHttpGateway = 19080
    
}