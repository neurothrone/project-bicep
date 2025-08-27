targetScope = 'resourceGroup'

//!: --- Types ---
type keyVaultSkuNameType = 'standard' | 'premium'
type keyVaultSkuFamilyType = 'A' | 'B'

@export()
type keyVaultSettingsType = {
  @description('SKU name for the Key Vault.')
  keyVaultSkuName: keyVaultSkuNameType

  @description('SKU family for the Key Vault')
  keyVaultSkuFamily: keyVaultSkuFamilyType

  @description('Enable Key Vault for deployment')
  keyVaultEnabledForDeployment: bool

  @description('Enable Key Vault for template deployment')
  keyVaultEnabledForTemplateDeployment: bool
}

//!: --- Parameters ---
@description('Location for the Key Vault and resources.')
param location string

@description('Name of the Key Vault to create.')
param keyVaultName string

@description('Secrets to create in the Key Vault')
@secure()
param secretsObject object

@description('Settings for the Key Vault')
param settings keyVaultSettingsType

@description('Tags to apply to the resource')
param tags object

//!: --- Resources ---
resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: settings.keyVaultEnabledForDeployment
    enabledForTemplateDeployment: settings.keyVaultEnabledForTemplateDeployment
    sku: {
      name: settings.keyVaultSkuName
      family: settings.keyVaultSkuFamily
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
