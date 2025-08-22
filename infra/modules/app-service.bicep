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

// !: --- Resources ---
resource appServicePlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: planName
  location: location
  sku: {
    name: skuName
//     tier: 'Basic'
    capacity: capacity
  }
  properties: {
    reserved: true // Linux plan (set to false for Windows)
    //     perSiteScaling: false
    //     maximumElasticWorkerCount: 1
  }
}

resource webApp 'Microsoft.Web/sites@2024-11-01' = {
  name: siteName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: httpsOnly
//     siteConfig: {
//       ftpsState: 'Disabled'
//     }
  }
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
output defaultHostName string = webApp.properties.defaultHostName
