param naming object
param location string = resourceGroup().location
param tags object
param sendGridApiKey string

@allowed([
  'prod'
  'dev'
])
param environmentType string = 'dev'

var subnetcidrs = {

  app: '10.0.0.0/24'
  bastion: '10.0.1.0/26'
  default: '10.0.1.128/25'
  devops: '10.0.1.64/26'
  frontend: '10.0.2.0/24'

}

param vnetcidr string = '10.0.0.0/16'
param publicNetworkAccess string = 'Disabled'
param createBlobPrivateEndpoint bool = true
param createFunctionEndpointIngest bool = true
param createFunctionEndpointProcess bool = true
param createKeyVaultPrivateEndpoint bool = true
param createEventHubPrivateEndpoint bool = true
param createServiceBusPrivateEndpoint bool = true 
@allowed([
  'Hot'
  'Cold'
  'Premium'
])
param storageAccessTier string = 'Hot'

var resourceNames = {
  ingestFuncApp: replace(naming.functionApp.name, '${naming.functionApp.slug}-', '${naming.functionApp.slug}-ingestor-')
  processorFuncApp: replace(naming.functionApp.name, '${naming.functionApp.slug}-', '${naming.functionApp.slug}-processor-')
  notifierFuncApp: replace(naming.functionApp.name, '${naming.functionApp.slug}-', '${naming.functionApp.slug}-notifier-')
  applicationInsights: naming.applicationInsights.name
  keyVault: naming.keyVault.nameUnique
  eventHubsNamespace: naming.eventHubNamespace.name
  eventHub: naming.eventHub.name
  eventHubConsumerGroup: naming.eventHubConsumerGroup.name
  serviceBusNamespace: naming.serviceBusNamespace.name
  dataStorageAccount: naming.storageAccount.nameUnique
  containerRegistry: naming.containerRegistry.name
  streamAnalyticsJobName: naming.streamAnalyticsJob.name
  vnetName: naming.virtualNetwork.name
}


var secretNames = {
  dataStorageConnectionString: 'dataStorageConnectionString'
  serviceBusConnectionString: 'serviceBusConnectionString'
  eventHubsNamespaceConnectionString: 'eventHubsNamespaceConnectionString'
  sendGridApiKey: 'sendGridApiKey'
}

var functionSkuName = environmentType == 'poc' ? 'Y1' : 'EP1'


var createPrivateEndpoints = {

  createBlobPrivateEndpoint: createBlobPrivateEndpoint
  createFunctionEndpointIngest: createFunctionEndpointIngest
  createFunctionEndpointProcess: createFunctionEndpointProcess
  createKeyVaultPrivateEndpoint: createKeyVaultPrivateEndpoint
  createEventHubPrivateEndpoint: createEventHubPrivateEndpoint
  createServiceBusPrivateEndpoint: createServiceBusPrivateEndpoint

}

var dnsNames = {

  functionPrivateDnsName: 'privatelink.azurewebsites.net' //specific for azure apps/functions
  blobPrivateDnsName: 'privatelink.blob.${environment().suffixes.storage}' //privatelink.blob.core.windows.net
  keyvaultPrivateDnsName: 'privatelink${environment().suffixes.keyvaultDns}'
  eventHubsPrivateDnsName: 'privatelink.servicebus.windows.net'
  serviceBussPrivateDnsName: 'privatelink.servicebus.windows.net'
}

var privateEndpointResources = {

  functionPrivateEndpointResource : 'sites'
  blobPrivateEndpointResource: 'blob'
  keyvaultPrivateEnpointResource: 'vault'
  eventHubsPrivateEnpointResource: 'namespace'
  serviceBusPrivateEnpointResource: 'namespace'
}

module applicationInsights 'modules/appInsights.module.bicep' = {
  name: 'applicationInsights'
  params:{
    name: resourceNames.applicationInsights
    location: location
    project: naming.applicationInsights.name
  }
}

module vnet 'modules/vnet.module.bicep' = {
  name: 'vnet'
  params:{
    name: resourceNames.vnetName
    location: location
    addressPrefix: vnetcidr
    appSnet: {
      addressPrefix: subnetcidrs.app
    }
    bastionSnet: {
      addressPrefix: subnetcidrs.bastion
    }
    defaultSnet: {
      addressPrefix: subnetcidrs.default
      // vnet integration for the function app
      delegations: [
        {
          name: 'functionsintegration'
          properties: {
            serviceName: 'Microsoft.Web/serverfarms'
          }
        }
      ]      
    }
    devOpsSnet: {
      addressPrefix: subnetcidrs.devops
    }
    frontendIntegrationSnet: {
      addressPrefix: subnetcidrs.frontend
      // vnet integration for the function app - temporarily
      delegations: [
        {
          name: 'functionsintegration'
          properties: {
            serviceName: 'Microsoft.Web/serverfarms'
          }
        }
      ]            
    }
  }
}

//Create Storage account and -conditionally- private endpoint

module dataStorageAccount 'modules/storage.module.bicep' = {
  name: 'dataStorageAccount'
  params: {
    location: location
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    name: resourceNames.dataStorageAccount
    accessTier: storageAccessTier
    publicNetworkAccess: publicNetworkAccess //Allow or Disallow Public Access
    privateEndpoint: createPrivateEndpoints.createBlobPrivateEndpoint //Create or not a private endpoint
    //Private endpoint config
    blobPrivateDnsName: dnsNames.blobPrivateDnsName 
    privateDnsVnet: vnet.outputs.vnetId
    privateEndpointSubResource: privateEndpointResources.blobPrivateEndpointResource
    privateEndpointSubnet: vnet.outputs.appSnetId
    tags: tags

  }
}

//ingest function integrated into main vnet on front subnet

module ingestFuncApp './modules/functionApp.module.bicep' = {
  name: 'ingestFuncApp'
  params: {
    location: location
    name: resourceNames.ingestFuncApp
    managedIdentity: true
    tags: tags
    skuName: functionSkuName
    //Vnet Integration
    vnetintegration: true
    subnetIdForIntegration: vnet.outputs.frontendIntegrationSnetId
    //Private Endpoint
    privateEndpoint: createPrivateEndpoints.createFunctionEndpointIngest //Create or not a private endpoint
    //Private endpoint config
    functionPrivateDnsName: dnsNames.functionPrivateDnsName 
    privateDnsVnet: vnet.outputs.vnetId
    privateEndpointSubResource: privateEndpointResources.functionPrivateEndpointResource
    privateEndpointSubnet: vnet.outputs.appSnetId
    appInsInstrumentationKey: applicationInsights.outputs.instrumentationKey
    funcAppSettings: [
      {
        name: 'DataStorageConnection'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.dataStorageConnectionString})'
      }
      {
        name: 'ServiceBusConnection'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.serviceBusConnectionString})'
      }
      {
        name: 'EventHubsConnection'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.eventHubsNamespaceConnectionString})'
      }
      {
        name: 'EventHubName'
        value: resourceNames.eventHub
      }
    ]
  }
}
//processor function integrated into main vnet on default subnet
module processorFuncApp './modules/functionApp.module.bicep' = {
  name: 'processorFuncApp'
  params: {
    location: location
    name: resourceNames.processorFuncApp
    managedIdentity: true
    tags: tags
    skuName: functionSkuName
    vnetintegration: true
    subnetIdForIntegration: vnet.outputs.defaultSnetId    
    //Private Endpoint
    privateEndpoint: createPrivateEndpoints.createFunctionEndpointProcess //Create or not a private endpoint
    //Private endpoint config
    functionPrivateDnsName: dnsNames.functionPrivateDnsName 
    privateDnsVnet: vnet.outputs.vnetId
    privateEndpointSubResource: privateEndpointResources.functionPrivateEndpointResource
    privateEndpointSubnet: vnet.outputs.appSnetId 
    appInsInstrumentationKey: applicationInsights.outputs.instrumentationKey
    funcAppSettings: [
      {
        name: 'DataStorageConnection'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.dataStorageConnectionString})'
      }
      {
        name: 'ServiceBusConnection'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.serviceBusConnectionString})'
      }
      {
        name: 'EventHubsConnection'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.eventHubsNamespaceConnectionString})'
      }
      {
        name: 'EventHubName'
        value: resourceNames.eventHub
      }
      {
        name: 'EventHubConsumerGroup'
        value: resourceNames.eventHubConsumerGroup
      }
    ]
  }
}

// module notifierFuncApp './modules/functionApp.module.bicep' = {
//   name: 'notifierFuncApp'
//   params: {
//     location: location
//     name: resourceNames.notifierFuncApp
//     managedIdentity: true
//     tags: tags
//     skuName: functionSkuName
//     appInsInstrumentationKey: applicationInsights.outputs.instrumentationKey
//     funcAppSettings: [
//       {
//         name: 'DataStorageConnection'
//         value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.dataStorageConnectionString})'
//       }
//       {
//         name: 'ServiceBusConnection'
//         value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.serviceBusConnectionString})'
//       }
//       {
//         name: 'EventHubsConnection'
//         value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.eventHubsNamespaceConnectionString})'
//       }
//       {
//         name: 'SendGridApiKey'
//         value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.sendGridApiKey})'
//       }
//     ]
//   }
// }

module keyVault 'modules/keyvault.module.bicep' = {
  name: 'keyVault'
  params: {
    name: resourceNames.keyVault
    location: location
    skuName: 'standard'
    tags: tags
    privateEndpoint: createPrivateEndpoints.createKeyVaultPrivateEndpoint
    //Private endpoint config
    keyVaultPrivateDnsName: dnsNames.keyvaultPrivateDnsName 
    privateDnsVnet: vnet.outputs.vnetId
    privateEndpointSubResource: privateEndpointResources.keyvaultPrivateEnpointResource
    privateEndpointSubnet: vnet.outputs.appSnetId   
    accessPolicies: [
      {
        tenantId: ingestFuncApp.outputs.identity.tenantId
        objectId: ingestFuncApp.outputs.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
      {
        tenantId: processorFuncApp.outputs.identity.tenantId
        objectId: processorFuncApp.outputs.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
      // {
      //   tenantId: notifierFuncApp.outputs.identity.tenantId
      //   objectId: notifierFuncApp.outputs.identity.principalId
      //   permissions: {
      //     secrets: [
      //       'get'
      //     ]
      //   }
      // }
    ]
    secrets: [
      {
        name: secretNames.dataStorageConnectionString
        value: dataStorageAccount.outputs.connectionString
      }
      {
        name: secretNames.serviceBusConnectionString
        value: serviceBus.outputs.connectionString
      }
      {
        name: secretNames.eventHubsNamespaceConnectionString
        value: eventHub.outputs.namespaceConnectionString
      }
      {
        name: secretNames.sendGridApiKey
        value: sendGridApiKey
      }
    ]
  }
}

////Event Hubs

//create event hub namespace and hub
module eventHub './modules/eventHubs.module.bicep' = {
  name: 'eventHub'
  params: {
    name: resourceNames.eventHubsNamespace
    location: location
    eventHubSku: 'Standard'
    eventHubName: resourceNames.eventHub
    consumerGroupName: resourceNames.eventHubConsumerGroup
    privateEndpoint: createPrivateEndpoints.createEventHubPrivateEndpoint
    //Private endpoint config
    eventhubsPrivateDnsName: dnsNames.eventHubsPrivateDnsName 
    privateDnsVnet: vnet.outputs.vnetId
    privateEndpointSubResource: privateEndpointResources.eventHubsPrivateEnpointResource
    privateEndpointSubnet: vnet.outputs.appSnetId       
    tags: tags
  }
}

//ServiceBus

module serviceBus 'modules/servicebus.module.bicep' = {
  name: 'serviceBus'
  params: {
    location: location
    skuName: environmentType == 'poc' ? 'Standard' : 'Premium'
    name: resourceNames.serviceBusNamespace
    privateEndpoint: createPrivateEndpoints.createServiceBusPrivateEndpoint
    //Private endpoint config
    serviceBusPrivateDnsName: dnsNames.serviceBussPrivateDnsName 
    privateDnsVnet: vnet.outputs.vnetId
    privateEndpointSubResource: privateEndpointResources.serviceBusPrivateEnpointResource
    privateEndpointSubnet: vnet.outputs.appSnetId      
    tags: tags
  }
}

// module containerRegistry 'modules/containerRegistry.module.bicep' = {
//   name: 'containerRegistry'
//   params: {
//     location: location
//     name: resourceNames.containerRegistry
//     tags: tags
//   }
// }

module streamAnalyticsJob 'modules/streamAnalyticsJob.module.bicep' = {
  name: 'streamAnalyticsJob'
  params: {
    location: location
    name: resourceNames.streamAnalyticsJobName
    tags: tags
    numberOfStreamingUnits: 1
  }
}

output storageAccountName string = dataStorageAccount.outputs.name
output ingestorFunctionAppName string = ingestFuncApp.outputs.name
output processorFunctionAppName string = processorFuncApp.outputs.name
// output notifierFunctionAppName string = notifierFuncApp.outputs.name
