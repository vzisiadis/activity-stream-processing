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
  ingestintegration: '10.0.2.0/26'
  processingestintegration: '10.0.2.64/26'
  notifyintegration: '10.0.2.128/26'
}

param vnetcidr string = '10.0.0.0/16'
param publicNetworkAccess string = 'Disabled'
param createBlobPrivateEndpoint bool = true
param createFunctionEndpointIngest bool = true
param createFunctionEndpointProcess bool = true
param createFunctionEndpointNotify bool = true
param createKeyVaultPrivateEndpoint bool = true
param createEventHubPrivateEndpoint bool = true
param createServiceBusPrivateEndpoint bool = true 
@allowed([
  'Hot'
  'Cold'
  'Premium'
])
param storageAccessTier string = 'Hot'
@allowed([
  'Enabled'
  'Disabled'
])
param serviceBusPublicNetworkAccess string = 'Disabled'
@allowed([
  'Enabled'
  'Disabled'
])
param eventHubsPublicNetworkAccess string = 'Disabled'
param keyVaultPublicNetworkAccess string = 'disabled'


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
  createFunctionEndpointNotify: createFunctionEndpointNotify
  createKeyVaultPrivateEndpoint: createKeyVaultPrivateEndpoint
  createEventHubPrivateEndpoint: createEventHubPrivateEndpoint
  createServiceBusPrivateEndpoint: createServiceBusPrivateEndpoint

}

var dnsNames = {

  functionPrivateDnsName: 'privatelink.azurewebsites.net' //specific for azure apps/functions
  blobPrivateDnsName: 'privatelink.blob.${environment().suffixes.storage}' //privatelink.blob.core.windows.net
  keyvaultPrivateDnsName: 'privatelink${environment().suffixes.keyvaultDns}'
  namespacePrivateDnsName: 'privatelink.servicebus.windows.net'
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
    }
    devOpsSnet: {
      addressPrefix: subnetcidrs.devops
    }
    ingestIntegrationSnet: {
      addressPrefix: subnetcidrs.ingestintegration
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
    processIntegrationSnet: {
      addressPrefix: subnetcidrs.processingestintegration
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
    notifyIntegrationSnet: {
      addressPrefix: subnetcidrs.notifyintegration
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

//Private DNS for function apps
//Only when private link is needed for any of the functions

module privatednsfunctions './/modules/privateDnsZone.module.bicep'= if ((createPrivateEndpoints.createFunctionEndpointIngest) || (createPrivateEndpoints.createFunctionEndpointProcess) || (createPrivateEndpoints.createFunctionEndpointNotify)) {
  name: 'privatednsfunctions'
  params:{
    name: dnsNames.functionPrivateDnsName 
    vnetIds: [vnet.outputs.vnetId]
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
    subnetIdForIntegration: vnet.outputs.ingestIntegrationSnetId
    //Private Endpoint
    privateEndpoint: createPrivateEndpoints.createFunctionEndpointIngest //Create or not a private endpoint
    //Private endpoint config
    privateDnsZoneId: privatednsfunctions.outputs.id
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
    subnetIdForIntegration: vnet.outputs.processIntegrationSnetId    
    //Private Endpoint
    privateEndpoint: createPrivateEndpoints.createFunctionEndpointProcess //Create or not a private endpoint
    //Private endpoint config
    privateDnsZoneId: privatednsfunctions.outputs.id
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

module notifierFuncApp './modules/functionApp.module.bicep' = {
  name: 'notifierFuncApp'
  params: {
    location: location
    name: resourceNames.notifierFuncApp
    managedIdentity: true
    tags: tags
    skuName: functionSkuName
    vnetintegration: true
    subnetIdForIntegration: vnet.outputs.notifyIntegrationSnetId    
    //Private Endpoint
    privateEndpoint: createPrivateEndpoints.createFunctionEndpointNotify //Create or not a private endpoint
    //Private endpoint config
    privateDnsZoneId: privatednsfunctions.outputs.id
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
        name: 'SendGridApiKey'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.sendGridApiKey})'
      }
    ]
  }
}

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
    publicNetworkAccess: keyVaultPublicNetworkAccess
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
      {
        tenantId: notifierFuncApp.outputs.identity.tenantId
        objectId: notifierFuncApp.outputs.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
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


//create private dns for eventhubs and service bus (common dns)
module privatednsnamespace './modules/privateDnsZone.module.bicep' = if ((createPrivateEndpoints.createEventHubPrivateEndpoint) || (createPrivateEndpoints.createServiceBusPrivateEndpoint)) {
  name: 'privatednsnamespace'
  params:{
    name: dnsNames.namespacePrivateDnsName 
    vnetIds: [vnet.outputs.vnetId]
    tags: tags
  }
}

//create event hub namespace and hub
module eventHub './modules/eventHubs.module.bicep' = {
  name: 'eventHub'
  params: {
    name: resourceNames.eventHubsNamespace
    location: location
    eventHubSku: 'Standard'
    eventHubName: resourceNames.eventHub
    consumerGroupName: resourceNames.eventHubConsumerGroup
    publicNetworkAccess: eventHubsPublicNetworkAccess
    privateEndpoint: createPrivateEndpoints.createEventHubPrivateEndpoint
    //Private endpoint config
    privateDnsZoneId: privatednsnamespace.outputs.id
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
    publicNetworkAccess: serviceBusPublicNetworkAccess
    privateEndpoint: createPrivateEndpoints.createServiceBusPrivateEndpoint
    //Private endpoint config
    privateDnsZoneId: privatednsnamespace.outputs.id
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
output notifierFunctionAppName string = notifierFuncApp.outputs.name
