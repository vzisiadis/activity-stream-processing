param name string
param location string
param tags object = {}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
    anonymousPullEnabled: false
    networkRuleBypassOptions: 'AzureServices'
  }
}

output id string = containerRegistry.id
output loginServer string = containerRegistry.properties.loginServer
output adminUserName string = containerRegistry.listCredentials().username
output adminPassword string = containerRegistry.listCredentials().passwords[0].value
