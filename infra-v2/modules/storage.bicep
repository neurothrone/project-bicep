targetScope = 'resourceGroup'

// !: --- Types ---
type storageAccountSkuType = 'Standard_LRS' | 'Standard_GRS' | 'Standard_ZRS' | 'Premium_LRS'
type storageAccountKindType = 'StorageV2' | 'FileStorage' | 'BlockBlobStorage'

@export()
type storageSettingsType = {
  @description('SKU name, e.g. Standard_LRS, Standard_GRS, Standard_ZRS, Premium_LRS')
  storageAccountSku: storageAccountSkuType

  @description('Storage kind, e.g. StorageV2, FileStorage, BlockBlobStorage')
  storageAccountKind: storageAccountKindType
}

// !: --- Parameters ---
@description('Deployment location (must be a valid Azure region)')
param location string

@description('Storage account name (3-24 lowercase letters and numbers)')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Settings for the Storage Account')
param settings storageSettingsType

@description('Tags to apply to the resource')
param tags object

// !: --- Resources ---
resource storage 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  sku: { name: settings.storageAccountSku }
  kind: settings.storageAccountKind
  // TODO: explore properties
  //   properties: {
  //     accessTier: 'Hot'
  //     supportsHttpsTrafficOnly: true
  //     allowBlobPublicAccess: true
  //     minimumTlsVersion: 'TLS1_2'
  //   }
  tags: tags
}

// !: --- Outputs ---
@description('Storage account resource id')
output idOutput string = storage.id

@description('Storage account name')
output nameOutput string = storage.name

@description('Primary Blob Endpoint URL for the Storage Account')
output primaryBlobEndpointOutput string = storage.properties.primaryEndpoints.blob
