targetScope = 'subscription'

param resources_suffix string
param location string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'resource-group-${resources_suffix}'
  location: location
}

module services './services.bicep' = {
  scope: resourceGroup
  name: 'services'
  params: {
    resources_suffix: resources_suffix
    location: location
  }
}
