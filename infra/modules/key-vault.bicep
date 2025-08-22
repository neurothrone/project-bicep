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

@description('Name of the Web App to provide access to the Key Vault.')
param webAppName string

@description('ID of the App Service Plan to associate with the Web App.')
param appServicePlanId string

@description('Enforce HTTPS for the Web App')
param httpsOnly bool

@description('Secrets to create in the Key Vault')
@secure()
param secretsObject object

@description('Permissions for the Web App to access secrets in the Key Vault')
@allowed([
  'get'
  'list'
])
param secretsPermissions array

@description('Tags to apply to the resource')
param tags object

//!: --- Resources ---
resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    sku: {
      name: skuName
      family: 'A'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: subscription().tenantId
        permissions: {
          secrets: secretsPermissions
        }
      }
    ]
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

resource webApp 'Microsoft.Web/sites@2024-11-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      appSettings: [
        for (secret, i) in secretsObject.secrets: {
          name: secret.secretName
          value: '@Microsoft.KeyVault(SecretUri=${secrets[i].properties.secretUriWithVersion})'
        }
      ]
    }
    httpsOnly: httpsOnly
  }
  tags: tags
}

resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2024-11-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: secretsPermissions
        }
      }
    ]
  }
}

//!: --- Outputs ---
@description('The name of the created Key Vault')
output keyVaultNameOutput string = keyVault.name

@description('The URI of the created Key Vault')
output keyVaultUriOutput string = keyVault.properties.vaultUri
