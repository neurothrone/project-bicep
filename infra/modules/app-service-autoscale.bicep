targetScope = 'resourceGroup'

// !: --- Types ---
type appServiceAutoScaleProfileType = {
  @description('Name of the autoscale profile')
  name: string

  @description('Capacity settings for the autoscale profile')
  capacity: {
    minimum: string
    maximum: string
    default: string
  }

  @description('CPU percentage threshold to scale out')
  scaleOutThreshold: int

  @description('CPU percentage threshold to scale in')
  scaleInThreshold: int
}

@export()
type appServiceAutoscaleSettingsType = {
  @description('Indicates whether autoscale is enabled for the App Service Plan')
  appServiceAutoscaleIsEnabled: bool

  @description('Autoscale profile settings for the App Service Plan')
  appServiceAutoscaleProfile: appServiceAutoScaleProfileType
}

// !: --- Parameters ---
@description('Location for the Key Vault and resources.')
param location string

@description('Name of the Autoscale Setting to create')
param autoscaleSettingName string

@description('Name of an existing App Service Plan to apply the autoscale settings to')
param appServicePlanName string

@description('Settings for configuring autoscale on the App Service Plan')
param settings appServiceAutoscaleSettingsType

@description('Tags to apply to the resource')
param tags object

// !: --- Variables ---
var appServicePlanResourceId = resourceId('Microsoft.Web/serverfarms', appServicePlanName)

// !: --- Resources ---
resource autoscaleSetting 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: autoscaleSettingName
  location: location
  properties: {
    enabled: settings.appServiceAutoscaleIsEnabled
    targetResourceUri: appServicePlanResourceId
    profiles: [
      {
        name: settings.appServiceAutoscaleProfile.name
        capacity: {
          minimum: settings.appServiceAutoscaleProfile.capacity.minimum
          maximum: settings.appServiceAutoscaleProfile.capacity.maximum
          default: settings.appServiceAutoscaleProfile.capacity.default
        }
        rules: [
          // Scale out on high CPU usage
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlanResourceId
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: settings.appServiceAutoscaleProfile.scaleOutThreshold
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          // Scale in on low CPU usage
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlanResourceId
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: settings.appServiceAutoscaleProfile.scaleInThreshold
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
  tags: tags
}
