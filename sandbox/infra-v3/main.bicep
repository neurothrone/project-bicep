metadata name = 'Project Bicep - Orchestrator'
metadata author = 'Neurothrone'
metadata description = 'Loops over environments and calls the per-environment module.'

targetScope = 'subscription'

// --- Imports ---
import { environmentType, tagsType } from 'types.bicep'
import { storageSettingsType } from './modules/storage.bicep'
import { keyVaultSettingsType } from './modules/key-vault.bicep'
import { appServiceSettingsType } from './modules/app-service.bicep'
import { appServiceAutoscaleSettingsType } from './modules/app-service-autoscale.bicep'

// --- Types ---
type environmentConfig = {
  environment: environmentType
  location: string
  storageSettings: storageSettingsType
  keyVaultSettings: keyVaultSettingsType
  appServiceSettings: appServiceSettingsType
  appServiceAutoscaleSettings: appServiceAutoscaleSettingsType
  resourceTags: tagsType
  solutionName: string
}

// --- Parameters ---
@description('Array of environments to deploy')
param environments array

@description('Secrets to create in the Key Vault (reused for all environments in this run)')
@secure()
param secretsObject object

@description('Permissions for the Web App to access secrets in the Key Vault')
@allowed([
  'get'
  'list'
])
param secretsPermissions array

@description('Timestamp shared across module instances (format: yyyyMMddHHmmss)')
param deploymentTimestamp string = utcNow('yyyyMMddHHmmss')

// --- Modules (loop) ---
module environmentModule 'environment.bicep' = [
  for env in environments: {
    name: 'env-${env.environment}-${deploymentTimestamp}'
    params: {
      environment: env.environment
      location: env.location
      storageSettings: env.storageSettings
      keyVaultSettings: env.keyVaultSettings
      appServiceSettings: env.appServiceSettings
      appServiceAutoscaleSettings: env.appServiceAutoscaleSettings
      secretsObject: secretsObject
      secretsPermissions: secretsPermissions
      resourceTags: env.resourceTags
      solutionName: env.solutionName
      deploymentTimestamp: deploymentTimestamp
    }
  }
]
