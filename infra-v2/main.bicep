metadata name = 'Project Bicep'
metadata author = 'Neurothrone'
metadata description = 'Bicep template for deploying a resource group, storage account, App Service Plan, Web App, and Key Vault (with secrets), including autoscale and access configuration. Designed for flexible environments (dev, test, prod) with customizable parameters and tagging support.'

targetScope = 'subscription'

// !: --- Imports ---
import { environmentType, tagsType } from 'types.bicep'
import { storageSettingsType } from './modules/storage.bicep'
import { keyVaultSettingsType } from './modules/key-vault.bicep'
import { appServiceSettingsType } from './modules/app-service.bicep'
import { appServiceAutoscaleSettingsType } from './modules/app-service-autoscale.bicep'

// !: --- Parameters ---
@description('Environment name, e.g., dev, test, prod')
param environment environmentType

@description('Deployment location (must be a valid Azure region)')
param location string

@description('Settings for the Storage Account')
param storageSettings storageSettingsType

@description('Settings for the Key Vault')
param keyVaultSettings keyVaultSettingsType

@description('Settings for the App Service Plan and Web App')
param appServiceSettings appServiceSettingsType

@description('Settings for the App Service Plan autoscale (only applied in prod environment)')
param appServiceAutoscaleSettings appServiceAutoscaleSettingsType

@description('Secrets to create in the Key Vault')
@secure()
param secretsObject object

@description('Permissions for the Web App to access secrets in the Key Vault')
@allowed([
  'get'
  'list'
])
param secretsPermissions array

@description('Tags to apply to all resources')
param resourceTags tagsType

@description('Solution name to be used in resource naming (alphanumeric, lowercase)')
param solutionName string = 'bicep'

@description('Timestamp to ensure unique resource names (format: yyyyMMddHHmmss)')
param deploymentTimestamp string = utcNow('yyyyMMddHHmmss')

// !: --- Variables ---
var resourceGroupBaseName = 'rg-${solutionName}-${uniqueString(subscription().id)}'
var resourceGroupFullName = '${resourceGroupBaseName}-${environment}'
var resourceGroupModuleName = '${resourceGroupBaseName}-${deploymentTimestamp}-${environment}'

var storageAccountBaseName = 'stg${uniqueString(subscription().id, resourceGroupFullName)}'
var storageAccountFullName = '${storageAccountBaseName}${environment}'
var storageModuleFullName = '${storageAccountBaseName}-${deploymentTimestamp}-${environment}'

var appServicePlanFullName = 'asp-${solutionName}-${uniqueString(subscription().id)}-${environment}'
var appServiceAppBaseName = 'app-${solutionName}-${uniqueString(subscription().id)}'
var appServiceAppFullName = '${appServiceAppBaseName}-${environment}'
var appServiceModuleName = '${appServiceAppBaseName}-${deploymentTimestamp}-${environment}'

var keyVaultFullName = 'kv${solutionName}${uniqueString(subscription().id)}${environment}'
var keyVaultModuleName = 'kv-${solutionName}-${deploymentTimestamp}-${environment}'

var keyVaultAccessModuleName = 'kv-access-${solutionName}-${deploymentTimestamp}-${environment}'

var appServiceAutoscaleBaseName = 'app-autoscale-${solutionName}'
var appServiceAutoscaleSettingsName = '${appServiceAutoscaleBaseName}-${environment}'
var appServiceAutoscaleModuleName = '${appServiceAutoscaleBaseName}-${deploymentTimestamp}-${environment}'

var secretNames = [for secret in secretsObject.secrets: secret.secretName]

// !: --- Modules ---
@description('Module to create the Resource Group')
module resourceGroupModule 'modules/resource-group.bicep' = {
  name: resourceGroupModuleName
  params: {
    location: location
    resourceGroupName: resourceGroupFullName
    tags: resourceTags
  }
}

@description('Module to create the Storage Account')
module storageModule 'modules/storage.bicep' = {
  name: storageModuleFullName
  scope: resourceGroup(resourceGroupFullName)
  params: {
    location: location
    storageAccountName: storageAccountFullName
    settings: storageSettings
    tags: resourceTags
  }
  dependsOn: [resourceGroupModule]
}

@description('Module to create the Key Vault and its secrets')
module keyVaultModule 'modules/key-vault.bicep' = {
  name: keyVaultModuleName
  scope: resourceGroup(resourceGroupFullName)
  params: {
    location: location
    keyVaultName: keyVaultFullName
    secretsObject: secretsObject
    settings: keyVaultSettings
    tags: resourceTags
  }
  dependsOn: [resourceGroupModule]
}

@description('Module to create the App Service Plan and Web App')
module appServiceModule 'modules/app-service.bicep' = {
  name: appServiceModuleName
  scope: resourceGroup(resourceGroupFullName)
  params: {
    environment: environment
    location: location
    appServiceAppName: appServiceAppFullName
    appServicePlanName: appServicePlanFullName
    keyVaultName: keyVaultFullName
    secretNames: secretNames
    settings: appServiceSettings
    tags: resourceTags
  }
  dependsOn: [resourceGroupModule, keyVaultModule]
}

@description('Module to grant the Web App access to the Key Vault')
module keyVaultAccessModule 'modules/key-vault-access.bicep' = {
  name: keyVaultAccessModuleName
  scope: resourceGroup(resourceGroupFullName)
  params: {
    keyVaultName: keyVaultFullName
    principalId: appServiceModule.outputs.principalIdOutput
    secretsPermissions: secretsPermissions
  }
  dependsOn: [keyVaultModule]
}

@description('Module to configure autoscale for the App Service Plan (only in prod environment)')
module appServiceAutoscale 'modules/app-service-autoscale.bicep' = if (environment == 'prod') {
  name: appServiceAutoscaleModuleName
  scope: resourceGroup(resourceGroupFullName)
  params: {
    location: location
    autoscaleSettingName: appServiceAutoscaleSettingsName
    appServicePlanName: appServicePlanFullName
    settings: appServiceAutoscaleSettings
    tags: resourceTags
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
