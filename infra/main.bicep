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

@description('Storage account base name (3-7 lowercase letters and numbers)')
@minLength(3)
@maxLength(7)
param storageBaseName string

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

@description('App Service Plan name')
param appServicePlanName string

@description('App Service Plan SKU name')
@allowed(['B1', 'S1'])
param appServicePlanSku string

@description('App Service Plan capacity (instances)')
param appServiceCapacity int

@description('App Service (site) name')
param appServiceSiteName string

@description('Enforce HTTPS for the App Service')
param appServiceHttpsOnly bool

// !: --- Variables ---
var resourceGroupFullName = 'rg-${resourceGroupName}-${environment}'

var resourceTags = {
  owner: 'Neurothrone'
  environment: environment
  costCenter: 'IT'
}

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
    // Storage name cannot exceed 24 characters and can only contain
    // lowercase letters and numbers.
    // - storageBaseName is max 7 characters
    // - uniqueString is 13 characters
    // - environment is max 4 characters
    name: '${storageBaseName}${uniqueString(subscription().id, resourceGroupFullName)}${environment}'
    skuName: storageSku
    kind: storageKind
    tags: resourceTags
  }
  dependsOn: [resourceGroupModule]
}

module appServiceModule 'modules/app-service.bicep' = {
  name: 'appServiceModule'
  scope: resourceGroup(resourceGroupFullName)
  params: {
    location: location
    planName: '${appServicePlanName}-${environment}'
    skuName: appServicePlanSku
    capacity: appServiceCapacity
    siteName: '${appServiceSiteName}-${environment}'
    httpsOnly: appServiceHttpsOnly
    environment: environment
    storageName: storageModule.outputs.nameOutput
    tags: resourceTags
  }
  dependsOn: [resourceGroupModule]
}

// !: --- Outputs ---
@description('The name of the created resource group')
output resourceGroupNameOutput string = resourceGroupModule.outputs.nameOutput

@description('The name of the created storage account')
output storageAccountNameOutput string = storageModule.outputs.nameOutput

@description('The URL of the deployed Web App')
output webAppUrlOutput string = appServiceModule.outputs.webAppUrlOutput
