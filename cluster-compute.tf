

locals {
    
    sf_settings_template = <<JSON

{
    "clusterEndpoint": "https://CLUSTER_NAME.eastus.cloudapp.azure.com:19000",
    "nodeTypeRef": "clustervm",
    "dataPath": "D:\\SvcFab",
    "durabilityLevel": "Bronze",
    "enableParallelJobs": true,
    "nicPrefixOverride": "INSERT_SUBNET_RANGE_HERE",
    "certificate": {
        "thumbprint": "INSERT_THUMBPRINT_HERE",
        "x509StoreName": "My"
    }
}

JSON

}


resource "azurerm_virtual_machine_scale_set" "cluster-scaleset" {

    name                = "${local.cluster_name}-scaleset"
    location            = "${azurerm_resource_group.cluster-rg.location}"
    resource_group_name = "${azurerm_resource_group.cluster-rg.name}"

    overprovision = false

    # automatic rolling upgrade
    upgrade_policy_mode  = "Automatic"

    sku {
        name     = "Standard_D2_V2"
        tier     = "Standard"
        capacity = 5
    }

    os_profile {
        computer_name_prefix = "clustervm"
        admin_username       = "${var.sf_username}"
        admin_password       = "${var.sf_password}"
    }

    os_profile_secrets {
        source_vault_id = "${var.sf_cluster_vault_url}"
        vault_certificates {
            certificate_url = "${var.sf_cluster_cert_url}"
            certificate_store = "My"
        }
    }

    storage_profile_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter-with-Containers"
        version   = "latest"
    }

    storage_profile_os_disk {
        caching           = "ReadOnly"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    network_profile {
        name    = "${local.cluster_name}-networkProfile"
        primary = true

        ip_configuration {
            primary = true
            name                                   = "${local.cluster_name}-nic"
            subnet_id                              = "${azurerm_subnet.cluster-subnet.id}"
            load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.cluster-lb-be-addr-pool.id}"]
            load_balancer_inbound_nat_rules_ids    = ["${azurerm_lb_nat_pool.lb-inbound-nat-pool.id}"]
        }
    }


    extension {
        name                        = "ServiceFabricNodeVmExt"
        publisher                   = "Microsoft.Azure.ServiceFabric"
        type                        = "ServiceFabricNode"
        type_handler_version        = "1.0"
        auto_upgrade_minor_version  = true

        settings = "$(local.sf_settings_template)"
        
    }


    tags = "${local.default_tags}"
}

output "template" {
  value = "${local.sf_settings_template}"
}