targetScope = 'resourceGroup'

// !: --- Parameters ---
@description('Location for the App Service resources')
param location string

@description('App Service Plan name')
param planName string

@description('App Service Plan SKU name')
@allowed(['F1', 'B1', 'S1'])
param skuName string

@description('App Service Plan capacity (instances)')
param capacity int

@description('App Service (Web App) name')
param siteName string

@description('Enforce HTTPS for the Web App')
param httpsOnly bool

@description('Environment name, e.g., dev, test, prod')
param environment string

@description('Storage account name')
param storageName string

@description('Tags to apply to the resource')
param tags object

// !: --- Variables ---
// Map SKU name to tier
var skuTier = {
  F1: 'Free'
  B1: 'Basic'
  S1: 'Standard'
}[skuName]

// !: --- Resources ---
resource appServicePlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: planName
  location: location
  sku: {
    name: skuName
    tier: skuTier
    capacity: capacity
  }
  properties: {
    reserved: true // Linux plan (set to false for Windows)
  }
  tags: tags
}

resource webApp 'Microsoft.Web/sites@2024-11-01' = {
  name: siteName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: httpsOnly
    siteConfig: {
      ftpsState: 'Disabled'
    }
  }
  tags: tags
}

resource webAppConfig 'Microsoft.Web/sites/config@2024-11-01' = {
  parent: webApp
  name: 'appsettings'
  properties: {
    ENVIRONMENT: environment
    STORAGE_NAME: storageName
    SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
  }
}

// !: --- Outputs ---
@description('The resource ID of the App Service Plan')
output appServicePlanIdOutput string = appServicePlan.id

@description('The name of the Web App')
output webAppNameOutput string = webApp.name

@description('Default host name of the Web App')
output defaultHostNameOutput string = webApp.properties.defaultHostName

@description('The URL of the Web App')
output webAppUrlOutput string = 'https://${webApp.properties.defaultHostName}'
