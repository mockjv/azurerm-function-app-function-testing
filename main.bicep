targetScope = 'subscription'

param resources_suffix string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'resource-group-${resources_suffix}'
  location: 'eastus'
}

module services './services.bicep' = {
  scope: resourceGroup
  name: 'services'
  params: {
    resources_suffix: resources_suffix
    location: 'eastus'
  }
}
