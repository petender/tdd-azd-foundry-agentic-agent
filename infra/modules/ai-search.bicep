// Azure AI Search — Free SKU (raw Bicep, no AVM available)

@description('AI Search service name.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

// ──────────────────────────────────────────────
// AI Search Service
// ──────────────────────────────────────────────

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

@description('Resource ID of the AI Search service.')
output resourceId string = searchService.id

@description('Name of the AI Search service.')
output resourceName string = searchService.name
