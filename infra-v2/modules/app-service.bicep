targetScope = 'resourceGroup'

// !: --- Imports ---
import { environmentType } from '../types.bicep'

// !: --- Types ---
type appServiceSkuNameType = 'F1' | 'B1' | 'S1'
type appServiceSkuTierType = 'Free' | 'Basic' | 'Standard'

type appServiceSkuType = {
  @description('App Service SKU name')
  appServiceSkuName: appServiceSkuNameType

  @description('App Service SKU tier')
  appServiceSkuTier: appServiceSkuTierType
}

@export()
type appServiceSettingsType = {
  @description('App Service Plan SKU')
  appServicePlanSku: appServiceSkuType

  @description('App Service Plan capacity (instances)')
  @minValue(1)
  @maxValue(10)
  appServicePlanInstanceCount: int

  @description('Deploy the App Service as Linux')
  appServiceIsLinux: bool

  @description('Enforce HTTPS for the Web App')
  appServiceHttpsOnly: bool
}

// !: --- Parameters ---
@description('Environment name, e.g., dev, test, prod')
param environment environmentType

@description('Deployment location (must be a valid Azure region)')
param location string

@description('App Service App name')
param appServiceAppName string

@description('App Service Plan name')
param appServicePlanName string

@description('Name of the Key Vault that the Web App will use')
param keyVaultName string

@description('Secrets that the Web App will use from an array')
param secretNames array

@description('Settings for the App Service Plan and Web App')
param settings appServiceSettingsType

@description('Tags to apply to the resource')
param tags object

// !: --- Variables ---
var staticAppSettings = {
  ENVIRONMENT: environment
  SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
}

var secretAppSettings = reduce(
  secretNames,
  {},
  (acc, secretName) =>
    union(acc, {
      '${secretName}': '@Microsoft.KeyVault(SecretName=${secretName};VaultName=${keyVaultName})'
    })
)

// !: --- Resources ---
resource appServicePlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: settings.appServicePlanSku.appServiceSkuName
    tier: settings.appServicePlanSku.appServiceSkuTier
    capacity: settings.appServicePlanInstanceCount
  }
  properties: { reserved: settings.appServiceIsLinux }
  tags: tags
}

resource appServiceApp 'Microsoft.Web/sites@2024-11-01' = {
  name: appServiceAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: settings.appServiceHttpsOnly
    siteConfig: {
      alwaysOn: environment == 'prod'
      ftpsState: 'Disabled'
    }
  }
  tags: tags
}

resource appServiceAppConfig 'Microsoft.Web/sites/config@2024-11-01' = {
  parent: appServiceApp
  name: 'appsettings'
  properties: union(staticAppSettings, secretAppSettings)
}

// !: --- Outputs ---
@description('The resource ID of the App Service Plan')
output appServicePlanResourceIdOutput string = appServicePlan.id

@description('The name of the Web App')
output webAppNameOutput string = appServiceApp.name

@description('Default host name of the Web App')
output defaultHostNameOutput string = appServiceApp.properties.defaultHostName

@description('The URL of the Web App')
output webAppUrlOutput string = '${settings.appServiceHttpsOnly ? 'https' : 'http'}://${appServiceApp.properties.defaultHostName}'

@description('The principal ID of the Web App identity')
output principalIdOutput string = appServiceApp.identity.principalId
