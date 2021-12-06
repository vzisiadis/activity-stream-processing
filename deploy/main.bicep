param naming object
param location string = resourceGroup().location
param tags object

@allowed([
  'prod'
  'dev'
])
param environmentType string = 'dev'

var resourceNames = {
  ingestFuncApp: replace(naming.functionApp.name, 'func-', 'func-ingestor-')
  processorFuncApp: replace(naming.functionApp.name, 'func-', 'func-processor-')
  notifierFuncApp: replace(naming.functionApp.name, 'func-', 'func-notifier-')
  keyVault: naming.keyVault.nameUnique
  eventHubsNamespace: naming.eventHubNamespace.name
  eventHub: naming.eventHub.name
  eventHubConsumerGroup: naming.eventHubConsumerGroup.name
  serviceBusNamespace: naming.serviceBusNamespace.name
  dataStorageAccount: naming.storageAccount.nameUnique
  containerRegistry: naming.containerRegistry.name
}

var secretNames = {
  dataStorageConnectionString: 'dataStorageConnectionString'
  serviceBusConnectionString: 'serviceBusConnectionString'
  eventHubsNamespaceConnectionString: 'eventHubsNamespaceConnectionString'
}

var functionSkuName = environmentType == 'dev' ? 'Y1' : 'EP1'

// Deploying a module, passing in the necessary naming parameters (storage account name should be also globally unique)
module dataStorageAccount 'modules/storage.module.bicep' = {
  name: 'dataStorageAccount'
  params: {
    location: location
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    name: resourceNames.dataStorageAccount
    tags: tags
  }
}

module ingestFuncApp './modules/functionApp.module.bicep' = {
  name: 'ingestFuncApp'
  params: {
    location: location
    name: resourceNames.ingestFuncApp
    managedIdentity: true
    tags: tags
    skuName: functionSkuName
    funcAppSettings: [
      {
        name: 'DataStorageConnection'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.dataStorageConnectionString})'
      }
      {
        name: 'ServiceBusConnection'
        value: serviceBus.outputs.connectionString
      }
      {
        name: 'EventHubsConnection'
        value: eventHub.outputs.namespaceConnectionString
      }
    ]
  }
}

module processorFuncApp './modules/functionApp.module.bicep' = {
  name: 'processorFuncApp'
  params: {
    location: location
    name: resourceNames.processorFuncApp
    managedIdentity: true
    tags: tags
    skuName: functionSkuName
    funcAppSettings: [
      {
        name: 'DataStorageConnection'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.dataStorageConnectionString})'
      }
      {
        name: 'ServiceBusConnection'
        value: serviceBus.outputs.connectionString
      }
      {
        name: 'EventHubsConnection'
        value: eventHub.outputs.namespaceConnectionString
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
    funcAppSettings: [
      {
        name: 'DataStorageConnection'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.dataStorageConnectionString})'
      }
      {
        name: 'ServiceBusConnection'
        value: serviceBus.outputs.connectionString
      }
      {
        name: 'EventHubsConnection'
        value: eventHub.outputs.namespaceConnectionString
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
    ]
  }
}

module eventHub './modules/eventHubs.module.bicep' = {
  name: 'eventHub'
  params: {
    name: resourceNames.eventHubsNamespace
    location: location
    eventHubSku: 'Standard'
    eventHubName: resourceNames.eventHub
    consumerGroupName: resourceNames.eventHubConsumerGroup
    tags: tags
  }
}

module serviceBus 'modules/servicebus.module.bicep' = {
  name: 'serviceBus'
  params: {
    location: location
    skuName: environmentType == 'dev' ? 'Standard' : 'Premium'
    name: resourceNames.serviceBusNamespace
    tags: tags
  }
}

module containerRegistry 'modules/containerRegistry.module.bicep' = {
  name: 'containerRegistry'
  params: {
    location: location
    name: resourceNames.containerRegistry
    tags: tags
  }
}

output storageAccountName string = dataStorageAccount.outputs.name
