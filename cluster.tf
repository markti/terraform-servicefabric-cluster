


resource "azurerm_service_fabric_cluster" "sf-cluster" {

    name                 = "${local.cluster_name}"
    resource_group_name  = "${azurerm_resource_group.cluster-rg.name}"
    location             = "${azurerm_resource_group.cluster-rg.location}"
    reliability_level    = "Silver"
    upgrade_mode         = "Automatic"
    vm_image             = "Windows"
    management_endpoint  = "https://${local.cluster_name}.eastus.cloudapp.azure.com:19080"

    certificate {
        thumbprint = "${var.sf_cluster_cert_thumb}"
        x509_store_name = "My"
    }

    add_on_features = ["DnsService", "RepairManager"]

    diagnostics_config {
        storage_account_name = "${azurerm_storage_account.diag-storage-acct.name}"
        protected_account_key_name = "StorageAccountKey1"
        blob_endpoint = "${azurerm_storage_account.diag-storage-acct.primary_blob_endpoint}"
        queue_endpoint = "${azurerm_storage_account.diag-storage-acct.primary_queue_endpoint}"
        table_endpoint = "${azurerm_storage_account.diag-storage-acct.primary_table_endpoint}"
    }

    fabric_settings {
        name = "Security"
        parameters = {
            "ClusterProtectionLevel" = "EncryptAndSign"
        }
    }

    reverse_proxy_certificate {
        thumbprint = "${var.sf_cluster_cert_thumb}"
        x509_store_name = "My"
    }

    azure_active_directory {
        tenant_id = "${var.tenant_id}"
        cluster_application_id = "${azuread_application.cluster-app.id}"
        client_application_id = "${azuread_application.client-app.id}"
    }

    node_type {
        name                        = "clustervm"
        instance_count              = 5
        is_primary                  = true
        client_endpoint_port        = 19000
        http_endpoint_port          = 19080
        reverse_proxy_endpoint_port = 19081
        durability_level            = "Bronze"

        application_ports {
            start_port = 20000
            end_port = 30000
        }

        ephemeral_ports {
            start_port = 49152
            end_port = 65534
        }
    }

    tags = "${local.default_tags}"
}