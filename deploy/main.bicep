param naming object
param location string = resourceGroup().location
param tags object

var resourceNames = { 
  ingestFuncApp: replace(naming.functionApp.name, 'func-', 'func-ingestor-')
  processorFuncApp: replace(naming.functionApp.name, 'func-', 'func-processor-')
  notificationFuncApp: replace(naming.functionApp.name, 'func-', 'func-notification-')
  keyVault: naming.keyVault.nameUnique
  eventHubsNamespace: naming.eventHubNamespace.name
  eventHub: naming.eventHub.name
  eventHubConsumerGroup: naming.eventHubConsumerGroup.name
  serviceBusNamespace: naming.serviceBusNamespace.name
}

var secretNames = {
  dataStorageConnectionString: 'dataStorageConnectionString'
  serviceBusConnectionString: 'serviceBusConnectionString'
}

// Deploying a module, passing in the necessary naming parameters (storage account name should be also globally unique)
module storage 'modules/storage.module.bicep' = {
  name: 'StorageAccountDeployment'
  params: {
    location: location
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    name: naming.storageAccount.nameUnique
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
    skuName: 'EP1'
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
    skuName: 'EP1'
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

module notificationFuncApp './modules/functionApp.module.bicep' = {
  name: 'notificationFuncApp'
  params: {
    location: location
    name: resourceNames.notificationFuncApp
    managedIdentity: true
    tags: tags
    skuName: 'EP1'
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

module eventHub './modules/eventHubs.module.bicep' = {
  name: 'eventHub'
  params: {
    name: resourceNames.eventHubsNamespace
    eventHubName: resourceNames.eventHub
    consumerGroupName: resourceNames.eventHubConsumerGroup
  }
}

module serviceBus 'modules/servicebus.module.bicep' = {
  name: 'serviceBus'
  params: {
    name: resourceNames.serviceBusNamespace
  }
}

output storageAccountName string = storage.outputs.name
