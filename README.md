# Terraforming a Service Fabric Cluster

Read steve-hawkins [post](https://github.com/terraform-providers/terraform-provider-azurerm/issues/1948) on 9/27/2018 and started trying to create a terraform template to replace the ARM template that I use to deploy my Service Fabric Cluster.


> you will also need to supply the resources required to run the Service Fabric cluster, as a minimum:-
> Storage Account (Service Fabric logging)
>  - Virtual Machine Scale Set (Microsoft Terraform guide)
>  - Public Load Balancer (for the VMSS rules)
>  - Key Vault (this is not essential, but will make sharing the certificates easier)
> This setup is the minimum that should get you started, further resources will be required for a secure, monitored, etc production ready Service Fabric cluster
> I also suggest reviewing the Microsoft Service Fabric Resource Manager documentation as well as the Quick Start Templates

## Prepping a cluster certificate

I used these [powershell scripts](https://github.com/ChackDan/Service-Fabric/tree/master/Scripts/ServiceFabricRPHelpers) to get the certificate into key vault. 'Invoke-AddCertToKeyVault' is the magic command that will take the cert and put it into KeyVault the way the RGT is expecting it.

Invoke-AddCertToKeyVault -SubscriptionId "<yourSubscription>" -ResourceGroupName <resourceGroupForVault> -Location eastus -VaultName "<yourVault>" -CertificateName "<certificateName>" -Password "<certificatePassword>" -UseExistingCertificate -ExistingPfxFilePath "C:\src\stuff\mycert.pfx"


## Getting it working...


While I find Microsoft's support here extremely disappointing, the process of reverse engineering the ARM template has really helped me fully understand each infrastructure component and its dependencies within the environment.

However there are some remaining things that I will need to fix to get it working:

1. Virtual Machine Scale Set Extensions
2. Service Fabric Cluster Configuration

Setting up the VNet, NSG, load balancer, storage accounts was pretty easy requiring little thought. However, the Virtual Machine Scaleset resource is a relatively lightly documented topic.

It appears that the extension's settings themselves are just a JSON string. However, in my Azure ARM Resource Group Template, that JSON can make references within the RGT document itself, whereas my terraform template can't. I will need to do some pretty gnarly string concatenation to get it working.

The Virtual Machine Scaleset has two extensions: 

1. ServiceFabricNode
2. IaaSDiagnostics


## ServiceFabricNode

ServiceFabricNode has both protectedSettings and settings. It's protected settings contains both keys for the log storage account:

```
"protectedSettings": {
    "StorageAccountKey1": "[listKeys(resourceId('Microsoft.Storage/storageAccounts', variables('supportLogStorageAccountName')),'2015-05-01-preview').key1]",
    "StorageAccountKey2": "[listKeys(resourceId('Microsoft.Storage/storageAccounts', variables('supportLogStorageAccountName')),'2015-05-01-preview').key2]"
}
```

I need to inject the following values:

1. azurerm_storage_account.log-storage-acct.primary_access_key
2. azurerm_storage_account.log-storage-acct.secondary_access_key


Example terraform JSON value:

protected_settings = "{\"StorageAccountKey1\": \"${azurerm_storage_account.log-storage-acct.primary_access_key}\", \"StorageAccountKey2\": \"${azurerm_storage_account.log-storage-acct.secondary_access_key}\"}"



It's settings contain a number of configuration settings:

```
{
    "clusterEndpoint": "[reference(parameters('clusterName')).clusterEndpoint]",
    "nodeTypeRef": "[variables('vmNodeType0Name')]",
    "dataPath": "D:\\SvcFab",
    "durabilityLevel": "Bronze",
    "enableParallelJobs": true,
    "nicPrefixOverride": "[variables('subnet0Prefix')]",
    "certificate": {
        "thumbprint": "[parameters('certificateThumbprint')]",
        "x509StoreName": "[parameters('certificateStoreValue')]"
    }
}
```

I need to inject the following values:

1. var.sf_cluster_cert_thumb
2. replace [parameters('certificateStoreValue')] with "My" constant
3. replace [variables('subnet0Prefix')] with "10.0.0.0/24" string constant, maybe this could be extracted in the future as I make reference of this in other places.
4. replcate [variables('vmNodeType0Name')] with the string constant I set for the node name
5. replace [reference(parameters('clusterName')).clusterEndpoint] with 'azurerm_service_fabric_cluster.sf-cluster.cluster_endpoint'. Apparently cluster_endpoint gets populated when provisioning the 'azurerm_service_fabric_cluster' resource.

## IaaSDiagnostics

IaaSDiagnostics has both protectedSettings and settings. It's protected settings contains both keys for the log storage account:

```
"protectedSettings": {
    "storageAccountName": "[variables('applicationDiagnosticsStorageAccountName')]",
    "storageAccountKey": "[listKeys(resourceId('Microsoft.Storage/storageAccounts', variables('applicationDiagnosticsStorageAccountName')),'2015-05-01-preview').key1]",
    "storageAccountEndPoint": "https://core.windows.net/"
}
```

I need to inject the following values:

1. azurerm_storage_account.diag-storage-acct.name
2. azurerm_storage_account.diag-storage-acct.primary_access_key

In the RGT, the storage account name is passed to a 'listkeys' and 'resourceId' methods which returns an object we can get 'key1' value from. I'm not sure if the same can be done in terraform or with the current azurerm provider. It looks like I should be able to use 'azurerm_storage_account.diag-storage-acct.primary_access_key' and it would work. If so this is even simpler syntax then the rather convoluted 'listKeys' and 'resourceId' methods being called.


It's settings contain a number of configuration settings:

```
{
    "WadCfg": {
        "DiagnosticMonitorConfiguration": {
        "overallQuotaInMB": "50000",
        "EtwProviders": {
            "EtwEventSourceProviderConfiguration": [
            {
                "provider": "Microsoft-ServiceFabric-Actors",
                "scheduledTransferKeywordFilter": "1",
                "scheduledTransferPeriod": "PT5M",
                "DefaultEvents": {
                "eventDestination": "ServiceFabricReliableActorEventTable"
                }
            },
            {
                "provider": "Microsoft-ServiceFabric-Services",
                "scheduledTransferPeriod": "PT5M",
                "DefaultEvents": {
                "eventDestination": "ServiceFabricReliableServiceEventTable"
                }
            }
            ],
            "EtwManifestProviderConfiguration": [
            {
                "provider": "cbd93bc2-71e5-4566-b3a7-595d8eeca6e8",
                "scheduledTransferLogLevelFilter": "Information",
                "scheduledTransferKeywordFilter": "4611686018427387904",
                "scheduledTransferPeriod": "PT5M",
                "DefaultEvents": {
                "eventDestination": "ServiceFabricSystemEventTable"
                }
            }
            ]
        }
        }
    },
    "StorageAccount": "[variables('applicationDiagnosticsStorageAccountName')]"
}
```

I need to inject the following values:

1. azurerm_storage_account.diag-storage-acct.name

Somehow I need to stuff all this stuff into a string and grab the storage account name from the "azurerm_storage_account" resource "diag-storage-acct".

## Troubleshooting

### Cluserid cannot be null or empty

VM has reported a failure when processing extension 'ServiceFabricNodeVmExt'. Error message: "Invalid operation. ClusterId cannot be null or empty.".

I'm assuming that this excerpt from the RGT 

```
[reference(parameters('clusterName')).clusterEndpoint] 
```

gets mapped into this: 

```
"clusterEndpoint": "https://${local.cluster_name}.eastus.cloudapp.azure.com:19000"
```

