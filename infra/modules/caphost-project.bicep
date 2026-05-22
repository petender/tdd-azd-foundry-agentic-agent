// Project-Level Capability Host — Deployed AFTER RBAC assignments
// This must be a separate module to break the circular dependency:
// ai-foundry (project MI) → RBAC → caphost-project

@description('AI Foundry Account name (parent of the project).')
param accountName string

@description('AI Foundry Project name.')
param projectName string

resource aiAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: accountName
}

resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' existing = {
  parent: aiAccount
  name: projectName
}

resource projectCapabilityHost 'Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview' = {
  parent: aiProject
  name: 'caphost-project'
  properties: {
    storageConnections: [
      'agent-storage'
    ]
    vectorStoreConnections: [
      'agent-search'
    ]
    threadStorageConnections: [
      'agent-cosmos'
    ]
  }
}
