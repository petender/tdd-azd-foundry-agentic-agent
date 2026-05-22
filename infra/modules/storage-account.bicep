// Storage Account for AI Foundry Agent file storage (AVM)

@description('Storage account name (max 24 chars, lowercase alphanumeric).')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Log Analytics Workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceResourceId string

// ──────────────────────────────────────────────
// Storage Account
// ──────────────────────────────────────────────

module storageAccount 'br/public:avm/res/storage/storage-account:0.14.0' = {
  name: '${name}-deploy'
  params: {
    name: name
    location: location
    tags: tags
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    blobServices: {
      containers: [
        {
          name: 'agent-storage'
        }
      ]
    }
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        metricCategories: [
          { category: 'Transaction' }
        ]
      }
    ]
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

@description('Resource ID of the storage account.')
output resourceId string = storageAccount.outputs.resourceId

@description('Name of the storage account.')
output resourceName string = storageAccount.outputs.name
