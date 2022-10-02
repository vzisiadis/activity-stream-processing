param keyVaultName string

@description('Array of name/value pairs')
#disable-next-line secure-secrets-in-params // Secret decoration cannot be applied to an array
param secrets array

resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2018-02-14' = [for secret in secrets: {
  name: '${keyVaultName}/${secret.name}'
  properties: {
    value: secret.value
  }
}]

output secrets array = [for (item, i) in secrets: {
  id: keyVaultSecrets[i].id
  name: keyVaultSecrets[i].name
  type: keyVaultSecrets[i].type
  props: keyVaultSecrets[i].properties
  reference: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName:${keyVaultSecrets[i].name}'
}]
