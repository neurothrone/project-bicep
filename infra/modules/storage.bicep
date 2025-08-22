targetScope = 'resourceGroup'

// !: --- Parameters ---
@description('Storage account base name (3-24 lowercase letters and numbers)')
@minLength(3)
@maxLength(24)
param name string

@description('Deployment location (must be a valid Azure region)')
param location string

@description('SKU name, e.g. Standard_LRS, Standard_GRS, Standard_ZRS, Premium_LRS')
param skuName string

@description('Storage kind, e.g. StorageV2, FileStorage, BlockBlobStorage')
param kind string

// !: --- Resources ---
resource storage 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: name
  location: location
  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// !: --- Outputs ---
@description('Storage account resource id')
output idOutput string = storage.id

output nameOutput string = storage.name

@description('Primary Blob Endpoint URL for the Storage Account')
output primaryBlobEndpointOutput string = storage.properties.primaryEndpoints.blob
