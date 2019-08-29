# Terraforming a Service Fabric Cluster

Read steve-hawkins [post](https://github.com/terraform-providers/terraform-provider-azurerm/issues/1948) on 9/27/2018 and started trying to create a terraform template to replace the ARM template that I use to deploy my Service Fabric Cluster.


> you will also need to supply the resources required to run the Service Fabric cluster, as a minimum:-

> Storage Account (Service Fabric logging)
>  - Virtual Machine Scale Set (Microsoft Terraform guide)
>  - Public Load Balancer (for the VMSS rules)
>  - Key Vault (this is not essential, but will make sharing the certificates easier)

> This setup is the minimum that should get you started, further resources will be required for a secure, monitored, etc production ready Service Fabric cluster

> I also suggest reviewing the Microsoft Service Fabric Resource Manager documentation as well as the Quick Start Templates


The process of reverse engineering the ARM template has really helped me fully understand each infrastructure component and its dependencies within the environment.

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

## IaaSDiagnostics

