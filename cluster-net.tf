
resource "azurerm_virtual_network" "cluster-vnet" {

    name                = "${local.cluster_name}-vnet"
    resource_group_name = "${azurerm_resource_group.cluster-rg.name}"
    location            = "${azurerm_resource_group.cluster-rg.location}"
    address_space       = ["${var.vnet_address_space}"]

    tags = "${local.default_tags}"
}

resource "azurerm_subnet" "cluster-subnet" {
    name                        = "${local.cluster_name}-subnet1"
    resource_group_name         = "${azurerm_resource_group.cluster-rg.name}"
    virtual_network_name        = "${azurerm_virtual_network.cluster-vnet.name}"
    address_prefix              = "${var.subnet1_address_space}"
    network_security_group_id   = "${azurerm_network_security_group.cluster-nsg.id}"
}

resource "azurerm_public_ip" "cluster-pip" {
    name                = "${local.cluster_name}-pip"
    resource_group_name = "${azurerm_resource_group.cluster-rg.name}"
    location            = "${azurerm_resource_group.cluster-rg.location}"
    allocation_method   = "Dynamic"
    domain_name_label   = "${local.cluster_name}"

    tags = "${local.default_tags}"
}



resource "azurerm_network_security_group" "cluster-nsg" {
    name                = "${local.cluster_name}-nsg"
    location            = "${azurerm_resource_group.cluster-rg.location}"
    resource_group_name = "${azurerm_resource_group.cluster-rg.name}"

    security_rule {
        name                       = "allowSvcFabSMB"
        priority                   = 3950
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "445"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "allowSvcFabCluser"
        priority                   = 3920
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1025-1027"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "allowSvcFabEphemeral"
        priority                   = 3930
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "49152-65534"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "allowSvcFabPortal"
        priority                   = 3900
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "19080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "allowSvcFabClient"
        priority                   = 3910
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "19000"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "allowSvcFabApplication"
        priority                   = 3940
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "20000-30000"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "blockAll"
        priority                   = 4095
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "allowVNetRDP"
        priority                   = 3960
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389-4500"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "allowSvcFabReverseProxy"
        priority                   = 3980
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "19081"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "allowAppPort1"
        priority                   = 2001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "allowAppPort2"
        priority                   = 2002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = "${local.default_tags}"
}
