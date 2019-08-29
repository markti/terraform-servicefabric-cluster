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


resource "azurerm_service_fabric_cluster" "sf-cluster" {
  name                 = "${local.cluster_name}"
  resource_group_name  = "${azurerm_resource_group.cluster-rg.name}"
  location             = "${azurerm_resource_group.cluster-rg.location}"
  reliability_level    = "Bronze"
  upgrade_mode         = "Automatic"
  vm_image             = "Windows"
  management_endpoint  = "https://example:80"

  node_type {
    name                 = "first"
    instance_count       = 3
    is_primary           = true
    client_endpoint_port = 2020
    http_endpoint_port   = 80
  }
}