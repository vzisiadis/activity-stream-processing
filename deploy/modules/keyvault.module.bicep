param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Array of access policy configurations, schema ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/accesspolicies?tabs=json#microsoftkeyvaultvaultsaccesspolicies-object')
param accessPolicies array = []

@description('Secrets array with name/value pairs')
#disable-next-line secure-secrets-in-params // Secret decoration cannot be applied to an array
param secrets array = []
param privateEndpoint bool = true
param keyVaultPrivateDnsName string
param privateDnsVnet string
param privateEndpointSubResource string
param privateEndpointSubnet string

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: name
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    accessPolicies: accessPolicies
  }
  tags: tags
}

module secretsDeployment 'keyvault.secrets.module.bicep' = if (!empty(secrets)) {
  name: 'keyvault-secrets'
  params: {
    keyVaultName: keyVault.name
    secrets: secrets
  }
}

//Private Endpoint

//create the private dns zone and zone link for the vnet
//for all azure keyvaults
module privatednskeyvault './privateDnsZone.module.bicep'= if (privateEndpoint) {
  name: 'privatednskeyvault'
  params:{
    name: keyVaultPrivateDnsName 
    vnetIds: [privateDnsVnet]
    tags: tags
  }
}

//create the private endpoints and dns zone groups
///ingest function

module privateendpointkeyvault './privateEndpoint.module.bicep' = if (privateEndpoint) {
  name: 'privateendpointkeyvault'
  params:{
    name: 'privateendpointkeyvault'
    location: location
    privateDnsZoneId: privatednskeyvault.outputs.id
    privateLinkServiceId: keyVault.id
    subResource: privateEndpointSubResource
    subnetId: privateEndpointSubnet
    tags: tags
  }
}

output id string = keyVault.id
output name string = keyVault.name
output secrets array = secretsDeployment.outputs.secrets
