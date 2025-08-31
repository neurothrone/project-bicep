targetScope = 'resourceGroup'

//!: --- Parameters ---
@description('Name of an existing Key Vault to add access policies to')
param keyVaultName string

@description('Principal ID of the user, service principal, or managed identity to grant access to the Key Vault')
param principalId string

@description('Permissions for a resource to access secrets in the Key Vault')
@allowed([
  'get'
  'list'
])
param secretsPermissions array

//!: --- Resources ---
resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}

resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2024-11-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: principalId
        permissions: {
          secrets: secretsPermissions
        }
      }
    ]
  }
}
