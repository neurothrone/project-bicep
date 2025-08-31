targetScope = 'subscription'

// !: --- Parameters ---
@description('Deployment location (must be a valid Azure region)')
param location string

@description('Name of the resource group to create')
@minLength(1)
param resourceGroupName string

@description('Tags to apply to the resource')
param tags object

// !: --- Resources ---
resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// !: --- Outputs ---
@description('The name of the created resource group')
output nameOutput string = resourceGroup.name

@description('The location of the created resource group')
output locationOutput string = resourceGroup.location
