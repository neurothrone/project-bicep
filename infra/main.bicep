targetScope = 'subscription'

// !: --- Parameters ---
@description('Name of the resource group to create.')
param resourceGroupName string

@description('Primary location for all resources (deployment metadata location for subscription deployment).')
param location string

@description('Environment suffix (e.g. dev, test, prod)')
@minLength(3)
@maxLength(4)
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Storage SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param storageSku string

@description('Storage kind')
@allowed([
  'StorageV2'
  'FileStorage'
  'BlockBlobStorage'
])
param storageKind string

@description('App Service App name')
param appServiceAppName string

@description('App Service Plan name')
param appServicePlanName string

@description('App Service Plan SKU name')
@allowed(['B1', 'S1'])
param appServicePlanSku string

@description('App Service Plan capacity (instances)')
param appServiceCapacity int

@description('Enforce HTTPS for the App Service')
param appServiceHttpsOnly bool

@description('SKU name for the Key Vault')
@allowed([
  'standard'
  'premium'
])
param keyVaultSkuName string

@description('SKU family for the Key Vault')
@allowed([
  'A'
  'B'
])
param keyVaultSkuFamily string

@description('Enable Key Vault for deployment')
param keyVaultEnabledForDeployment bool

@description('Enable Key Vault for template deployment')
param keyVaultEnabledForTemplateDeployment bool

@description('Secrets to create in the Key Vault')
@secure()
param secretsObject object

@description('Permissions for the Web App to access secrets in the Key Vault')
@allowed([
  'get'
  'list'
])
param secretsPermissions array

@description('Minimum number of App Service Plan instances when autoscale is enabled')
param appServicePlanMinCapacity int

@description('Maximum number of App Service Plan instances when autoscale is enabled')
param appServicePlanMaxCapacity int

@description('Tags to apply to all resources')
param resourceTags object

// !: --- Variables ---
var resourceGroupFullName = 'rg-${resourceGroupName}-${environment}'
// Storage name cannot exceed 24 characters and can only contain
// lowercase letters and numbers.
// - storageBaseName is max 7 characters
// - uniqueString is 13 characters
// - environment is max 4 characters
var storageNameFull = 'storage${uniqueString(subscription().id, resourceGroupFullName)}${environment}'
var appServicePlanNameFull = '${appServicePlanName}-${environment}'
var appServiceAppNameFull = '${appServiceAppName}-${environment}'
var keyVaultNameFull = 'vault-${uniqueString(subscription().id, resourceGroupFullName)}-${environment}'

// !: --- Modules ---
module resourceGroupModule 'modules/resource-group.bicep' = {
  name: 'resourceGroupModule'
  params: {
    name: resourceGroupFullName
    location: location
    tags: resourceTags
  }
}

module storageModule 'modules/storage.bicep' = {
  name: 'storageModule'
  scope: resourceGroup(resourceGroupFullName)
  params: {
    location: location
    name: storageNameFull
    skuName: storageSku
    kind: storageKind
    tags: resourceTags
  }
  dependsOn: [resourceGroupModule]
}

module keyVaultModule 'modules/key-vault.bicep' = {
  name: 'keyVaultModule'
  scope: resourceGroup(resourceGroupFullName)
  params: {
    location: location
    keyVaultName: keyVaultNameFull
    skuName: keyVaultSkuName
    skuFamily: keyVaultSkuFamily
    enabledForDeployment: keyVaultEnabledForDeployment
    enabledForTemplateDeployment: keyVaultEnabledForTemplateDeployment
    secretsObject: secretsObject
    tags: resourceTags
  }
  dependsOn: [resourceGroupModule]
}

module appServiceModule 'modules/app-service.bicep' = {
  name: 'appServiceModule'
  scope: resourceGroup(resourceGroupFullName)
  params: {
    location: location
    appServiceAppName: appServiceAppNameFull
    appServicePlanName: appServicePlanNameFull
    skuName: appServicePlanSku
    capacity: appServiceCapacity
    httpsOnly: appServiceHttpsOnly
    environment: environment
    storageName: storageModule.outputs.nameOutput
    keyVaultName: keyVaultNameFull
    secretsObject: secretsObject
    tags: resourceTags
  }
  dependsOn: [resourceGroupModule, keyVaultModule]
}

module keyVaultAccessModule 'modules/key-vault-access.bicep' = {
  name: 'keyVaultAccessModule'
  scope: resourceGroup(resourceGroupFullName)
  params: {
    keyVaultName: keyVaultNameFull
    principalId: appServiceModule.outputs.principalIdOutput
    secretsPermissions: secretsPermissions
  }
  dependsOn: [keyVaultModule]
}

module appServiceAutoscale 'modules/app-service-autoscale.bicep' = if (environment == 'prod') {
  name: 'appServiceAutoscale'
  scope: resourceGroup(resourceGroupFullName)
  params: {
    location: location
    appServicePlanName: appServicePlanNameFull
    minCapacity: appServicePlanMinCapacity
    maxCapacity: appServicePlanMaxCapacity
  }
  dependsOn: [appServiceModule]
}

// !: --- Outputs ---
@description('The name of the created resource group')
output resourceGroupNameOutput string = resourceGroupModule.outputs.nameOutput

@description('The name of the created storage account')
output storageAccountNameOutput string = storageModule.outputs.nameOutput

@description('The URL of the deployed Web App')
output webAppUrlOutput string = appServiceModule.outputs.webAppUrlOutput
