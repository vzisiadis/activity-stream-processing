param name string
param location string = resourceGroup().location
param tags object = {}
param eventHubName string
param consumerGroupName string
param networkRuleName string = 'default'

@allowed([
  'Standard'
  'Basic'
])
param eventHubSku string = 'Standard'

@allowed([
  1
  2
  4
])
param skuCapacity int = 1
param privateDnsZoneId string
param privateEndpoint bool
param privateEndpointSubResource string
param privateEndpointSubnet string
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

resource namespace 'Microsoft.EventHub/namespaces@2021-06-01-preview' = {
  name: name
  location: location
  sku: {
    name: eventHubSku
    tier: eventHubSku
    capacity: skuCapacity
  }
  properties: {}
  tags: tags
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-06-01-preview' = {
  name: '${namespace.name}/${eventHubName}'
  properties: {}
}

resource authRule 'Microsoft.EventHub/namespaces/authorizationRules@2021-06-01-preview' = {
  name: '${namespace.name}/AppAuthRule'
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
}

resource consumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2021-06-01-preview' = {
  name: '${eventHub.name}/${consumerGroupName}'
  properties: {}  
}

resource networkrules 'Microsoft.EventHub/namespaces/networkRuleSets@2022-01-01-preview' = {
  name: '${namespace.name}/${networkRuleName}'
  properties:{
    publicNetworkAccess: publicNetworkAccess
  }
}

//create the private endpoints and dns zone groups
///ingest function

module privateendpointeventhubs './privateEndpoint.module.bicep' = if (privateEndpoint) {
  name: 'privateendpointeventhubs'
  params:{
    name: 'privateendpointeventhubs'
    location: location
    privateDnsZoneId: privateDnsZoneId
    privateLinkServiceId: namespace.id
    subResource: privateEndpointSubResource
    subnetId: privateEndpointSubnet
    tags: tags
  }
}


output eventHubNamespaceId string = namespace.id
output eventHubId string = eventHub.id
output namespaceConnectionString string = listkeys(authRule.id, authRule.apiVersion).primaryConnectionString
