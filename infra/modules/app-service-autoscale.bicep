targetScope = 'resourceGroup'

// !: --- Parameters ---
@description('Location for the App Service resources')
param location string

@description('Name of the App Service Plan to create autoscale settings for')
param appServicePlanName string

@description('Minimum number of instances for autoscale')
param minCapacity int

@description('Maximum number of instances for autoscale')
param maxCapacity int

// !: --- Resources ---
resource autoscaleSetting 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: 'autoscale-${appServicePlanName}'
  location: location
  properties: {
    enabled: true
    targetResourceUri: resourceId('Microsoft.Web/serverfarms', appServicePlanName)
    profiles: [
      {
        name: 'Default'
        capacity: {
          minimum: string(minCapacity)
          maximum: string(maxCapacity)
          default: string(minCapacity)
        }
        rules: [
          // Scale out on high CPU usage (>70%)
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: resourceId('Microsoft.Web/serverfarms', appServicePlanName)
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          // Scale in on low CPU usage (<30%)
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: resourceId('Microsoft.Web/serverfarms', appServicePlanName)
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
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
}
