targetScope = 'subscription'

// !: --- Parameters ---
@description('Name of the resource group to create')
@minLength(1)
param name string

@description('Location for the resource group')
param location string

// !: --- Resources ---
resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: name
  location: location
}

// !: --- Outputs ---
@description('The name of the created resource group')
output nameOutput string = resourceGroup.name

@description('The location of the created resource group')
output locationOutput string = resourceGroup.location
