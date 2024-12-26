targetScope = 'resourceGroup'

param resources_suffix string
param location string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'stor${resources_suffix}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource hostingPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'app-service-plan-${resources_suffix}'
  location: location
  sku: {
    name: 'P1v3'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: 'func-app-${resources_suffix}'
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
      ]
    }
    httpsOnly: true
  }
}

resource function 'Microsoft.Web/sites/functions@2024-04-01' = {
  parent: functionApp
  name: 'func'
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'req'
          type: 'httpTrigger'
          direction: 'in'
          authLevel: 'function'
          methods: [
            'get'
          ]
        }
        {
          name: 'res'
          type: 'http'
          direction: 'out'
        }
      ]
    }
    files: {
      'index.js': loadTextContent('funcs/func.js')
    }
  }
}
