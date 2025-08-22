targetScope = 'subscription'

// !: --- Parameters ---
@description('Name of the resource group to create')
param name string

@description('Location for the resource group')
param location string

// !: --- Resources ---
resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: name
  location: location
}

// !: --- Outputs ---
output nameOutput string = resourceGroup.name
output locationOutput string = resourceGroup.location
