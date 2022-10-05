param location string
param name string
param tags object = {}

@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param kind string = 'StorageV2'

@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_LRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param skuName string = 'Standard_LRS'

@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccess string
param privateEndpoint bool = false
param blobPrivateDnsName string
param privateDnsVnet string
param privateEndpointSubResource string
param privateEndpointSubnet string

@allowed([
  'Hot'
  'Cold'
  'Premium'
])
param accessTier string

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: toLower(take(replace(name, '-', ''), 24))
  location: location
  kind: kind
  sku: {
    name: skuName
  }
  tags: union(tags, {
    displayName: name
  })
  properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: publicNetworkAccess
  }
}

//create Private DNS zone for Blob and link to Vnet

module privatednsblob './privateDnsZone.module.bicep'= if (privateEndpoint) {
  name: 'privatednsblob'
  params:{
    name: blobPrivateDnsName
    vnetIds: [privateDnsVnet]
    tags: tags
  }
}

//create Private Endpoint and link to Private DNS

module privateendpointblob './privateEndpoint.module.bicep' = if (privateEndpoint) {
  name: 'privateendpointblob'
  params:{
    name: 'privateendpointblob'
    location: location
    privateDnsZoneId: privatednsblob.outputs.id
    privateLinkServiceId: storage.id
    subResource: privateEndpointSubResource
    subnetId: privateEndpointSubnet
    tags: tags
  }
}

output id string = storage.id
output name string = storage.name
output primaryKey string = listKeys(storage.id, storage.apiVersion).keys[0].value
output primaryEndpoints object = storage.properties.primaryEndpoints
output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.id, storage.apiVersion).keys[0].value}'
