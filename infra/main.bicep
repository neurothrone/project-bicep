targetScope = 'subscription'

// !: --- Parameters ---
@description('Base name for the resource group')
param resourceGroupBaseName string

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
param storageSku string

@description('Storage kind')
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

// !: --- Modules ---
module resourceGroupModule 'modules/resource-group.bicep' = {
  name: 'resourceGroupModule'
  params: {
    name: 'rg-${resourceGroupBaseName}-${environment}'
    location: location
  }
}

module storageModule 'modules/storage.bicep' = {
  name: 'storageModule'
  scope: resourceGroup(resourceGroupModule.name)
  params: {
    location: location
    // Storage name cannot exceed 24 characters and can only contain
    // lowercase letters and numbers.
    // - storageBaseName is max 7 characters
    // - uniqueString is 13 characters
    // - environment is max 4 characters
    name: '${storageBaseName}${uniqueString(resourceGroupModule.name)}${environment}'
    skuName: storageSku
    kind: storageKind
  }
}

module appServiceModule 'modules/app-service.bicep' = {
  name: 'appServiceModule'
  scope: resourceGroup(resourceGroupModule.name)
  params: {
    location: location
    planName: '${appServicePlanName}-${environment}'
    skuName: appServicePlanSku
    capacity: appServiceCapacity
    siteName: '${appServiceSiteName}-${environment}'
    httpsOnly: appServiceHttpsOnly
    environment: environment
    storageName: storageModule.name
  }
}

// !: --- Outputs ---
output resourceGroupNameOutput string = resourceGroupModule.name
output storageAccountNameOutput string = storageModule.outputs.nameOutput
output appServiceDefaultHostNameOutput string = appServiceModule.outputs.defaultHostName
