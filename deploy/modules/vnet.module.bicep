param name string
param location string = resourceGroup().location
param tags object = {}
param addressPrefix string
param includeBastion bool = true

param defaultSnet object
param appSnet object
param devOpsSnet object
param bastionSnet object
param ingestIntegrationSnet object
param processIntegrationSnet object
param notifyIntegrationSnet object

var defaultSnetConfig = {
  name: '${name}-default-snet'
  properties: defaultSnet
}

var appSnetConfig = {
  name: '${name}-app-snet'
  properties: appSnet
}

var devOpsSnetConfig = {
  name: '${name}-devops-snet'
  properties: devOpsSnet
}

var bastionSnetConfig = {
  name: 'AzureBastionSubnet'
  properties: bastionSnet
}

var ingestIntegrationSnetConfig = {
  name: '${name}-ingest-integration-snet'
  properties: ingestIntegrationSnet
}

var processIntegrationSnetConfig = {
  name: '${name}-process-integration-snet'
  properties: processIntegrationSnet
}

var notifyIntegrationSnetConfig = {
  name: '${name}-notify-integration-snet'
  properties: notifyIntegrationSnet
}


var fixedSubnets = [
  defaultSnetConfig
  appSnetConfig
  devOpsSnetConfig
  ingestIntegrationSnetConfig
  processIntegrationSnetConfig
  notifyIntegrationSnetConfig
]

var allSubnets = includeBastion ? union(fixedSubnets, [
  bastionSnetConfig
]) : fixedSubnets

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: allSubnets
  }
  tags: tags
}

output vnetId string = vnet.id
output defaultSnetId string = vnet.properties.subnets[0].id
output appSnetId string = vnet.properties.subnets[1].id
output devOpsSnetId string = vnet.properties.subnets[2].id
output ingestIntegrationSnetId string = vnet.properties.subnets[3].id
output processIntegrationSnetId string = vnet.properties.subnets[4].id
output notifyIntegrationSnetId string = vnet.properties.subnets[5].id
output bastionSnetId string = includeBastion ? vnet.properties.subnets[6].id : ''
