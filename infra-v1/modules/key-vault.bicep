targetScope = 'resourceGroup'

//!: --- Parameters ---
@description('Location for the Key Vault and resources.')
param location string

@description('Name of the Key Vault to create.')
param keyVaultName string

@description('SKU name for the Key Vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string

@description('SKU family for the Key Vault')
@allowed([
  'A'
  'B'
])
param skuFamily string

@description('Enable Key Vault for deployment')
param enabledForDeployment bool

@description('Enable Key Vault for template deployment')
param enabledForTemplateDeployment bool

@description('Secrets to create in the Key Vault')
@secure()
param secretsObject object

@description('Tags to apply to the resource')
param tags object

//!: --- Resources ---
resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    sku: {
      name: skuName
      family: skuFamily
    }
    tenantId: subscription().tenantId
    accessPolicies: []
  }
  tags: tags
}

resource secrets 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = [
  for secret in secretsObject.secrets: {
    parent: keyVault
    name: secret.secretName
    properties: {
      value: secret.secretValue
    }
  }
]

//!: --- Outputs ---
@description('The name of the created Key Vault')
output keyVaultNameOutput string = keyVault.name

@description('The URI of the created Key Vault')
output keyVaultUriOutput string = keyVault.properties.vaultUri
