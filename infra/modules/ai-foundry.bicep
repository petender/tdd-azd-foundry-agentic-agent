// Azure AI Foundry — Account (Hub) + Project + Model Deployment + Capability Host
// Raw Bicep — no AVM module available for AI Foundry resources

@description('AI Foundry Account (Hub) name.')
param accountName string

@description('AI Foundry Project name.')
param projectName string

@description('Azure region for AI Foundry resources (must support GPT-4o-mini).')
param location string

@description('Resource tags.')
param tags object

@description('Resource ID of the Storage Account for agent file storage.')
param storageAccountId string

@description('Name of the Storage Account.')
param storageAccountName string

@description('Resource ID of the Cosmos DB account for agent thread storage.')
param cosmosAccountId string

@description('Name of the Cosmos DB account.')
param cosmosAccountName string

@description('Resource ID of the AI Search service for agent vector store.')
param searchServiceId string

@description('Name of the AI Search service.')
param searchServiceName string

@description('Log Analytics Workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceId string

// ──────────────────────────────────────────────
// AI Foundry Account (Hub)
// ──────────────────────────────────────────────

resource aiAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: accountName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: accountName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    allowProjectManagement: true
  }
}

// ──────────────────────────────────────────────
// Diagnostic Settings for AI Foundry Account
// ──────────────────────────────────────────────

resource aiAccountDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${accountName}'
  scope: aiAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ──────────────────────────────────────────────
// GPT-4o-mini Model Deployment
// ──────────────────────────────────────────────

resource gpt4oMiniDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: aiAccount
  name: 'gpt-4.1-mini'
  sku: {
    name: 'Standard'
    capacity: 30
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4.1-mini'
      version: '2025-04-14'
    }
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}

// ──────────────────────────────────────────────
// AI Foundry Project (sub-resource of Account)
// ──────────────────────────────────────────────

resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: aiAccount
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Agentic Agent Demo Project'
    description: 'Azure AI Foundry project for multi-tool agentic agent demo with Code Interpreter, File Search, and Custom Functions.'
  }
  dependsOn: [
    gpt4oMiniDeployment
  ]
}

// ──────────────────────────────────────────────
// Project Connections — Storage, Cosmos DB, AI Search
// ──────────────────────────────────────────────

resource storageConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01' = {
  parent: aiProject
  name: 'agent-storage'
  properties: {
    category: 'AzureStorageAccount'
    target: 'https://${storageAccountName}.blob.${az.environment().suffixes.storage}'
    authType: 'AAD'
    metadata: {
      ResourceId: storageAccountId
      AccountName: storageAccountName
      ContainerName: 'agent-storage'
    }
  }
}

resource cosmosConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01' = {
  parent: aiProject
  name: 'agent-cosmos'
  properties: {
    category: 'CosmosDB'
    target: 'https://${cosmosAccountName}.documents.azure.com:443/'
    authType: 'AAD'
    metadata: {
      ResourceId: cosmosAccountId
    }
  }
}

resource searchConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01' = {
  parent: aiProject
  name: 'agent-search'
  properties: {
    category: 'CognitiveSearch'
    target: 'https://${searchServiceName}.search.windows.net'
    authType: 'AAD'
    metadata: {
      ResourceId: searchServiceId
    }
  }
}

// ──────────────────────────────────────────────
// Capability Host — Account Level
// ──────────────────────────────────────────────

resource accountCapabilityHost 'Microsoft.CognitiveServices/accounts/capabilityHosts@2025-04-01-preview' = {
  parent: aiAccount
  name: 'caphost-account'
  properties: {
    capabilityHostKind: 'Agents'
  }
  dependsOn: [
    aiProject
    storageConnection
    cosmosConnection
    searchConnection
  ]
}

// NOTE: Project-level caphost is in a separate module (caphost-project.bicep)
// to ensure RBAC assignments are in place before caphost provisioning.

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

@description('AI Foundry Account resource ID.')
output accountId string = aiAccount.id

@description('AI Foundry Account name.')
output accountName string = aiAccount.name

@description('AI Foundry Project name.')
output projectName string = aiProject.name

@description('AI Foundry Project endpoint for SDK access.')
output projectEndpoint string = 'https://${accountName}.cognitiveservices.azure.com/api/projects/${projectName}'

@description('Principal ID of the AI Foundry Project system-assigned managed identity.')
output projectPrincipalId string = aiProject.identity.principalId
