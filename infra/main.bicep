// Azure AI Foundry Agentic Agent — Main Orchestration
targetScope = 'resourceGroup'

// ──────────────────────────────────────────────
// Parameters
// ──────────────────────────────────────────────

@description('Azure region for supporting resources (Storage, Cosmos DB, AI Search, Monitoring).')
param location string

@description('Environment name (from azd).')
@minLength(1)
@maxLength(64)
param environment string

@description('Project name used in resource naming.')
param projectName string = 'foundryagent'

@description('Principal ID of the deploying user. Azure Developer CLI populates this automatically.')
param principalId string

@description('Azure region for AI Foundry Account — must support GPT-4o-mini. Defaults to swedencentral.')
param aiFoundryLocation string = 'swedencentral'

@description('Azure region for AI Search — fallback when primary region is capacity-constrained.')
param aiSearchLocation string = location

// ──────────────────────────────────────────────
// Variables
// ──────────────────────────────────────────────

var uniqueSuffix = uniqueString(resourceGroup().id)
var tags = {
  Environment: environment
  ManagedBy: 'Bicep'
  Project: projectName
  SecurityControl: 'Ignore'
}

// CAF naming
var logName = 'log-${projectName}-${environment}'
var appiName = 'appi-${projectName}-${environment}'
var stName = 'st${take(replace(projectName, '-', ''), 8)}${take(environment, 3)}${take(uniqueSuffix, 6)}'
var cosmosName = 'cosmos-${take(projectName, 10)}-${take(environment, 3)}-${take(uniqueSuffix, 6)}'
var searchName = 'search-${take(projectName, 10)}-${take(environment, 3)}-${take(uniqueSuffix, 6)}'
var aiAccountName = 'ai-${take(projectName, 10)}-${take(environment, 3)}-${take(uniqueSuffix, 6)}'
var aiProjectName = 'aiproj-${projectName}-${environment}'

// ──────────────────────────────────────────────
// Phase 1: Monitoring
// ──────────────────────────────────────────────

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-${uniqueSuffix}-deployment'
  params: {
    logAnalyticsName: logName
    appInsightsName: appiName
    location: location
    tags: tags
  }
}

// ──────────────────────────────────────────────
// Phase 2: Data Stores (parallel)
// ──────────────────────────────────────────────

module storageAccount 'modules/storage-account.bicep' = {
  name: 'storage-${uniqueSuffix}-deployment'
  params: {
    name: stName
    location: location
    tags: tags
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

module cosmosDb 'modules/cosmos-db.bicep' = {
  name: 'cosmos-${uniqueSuffix}-deployment'
  params: {
    name: cosmosName
    location: location
    tags: tags
  }
}

module aiSearch 'modules/ai-search.bicep' = {
  name: 'search-${uniqueSuffix}-deployment'
  params: {
    name: searchName
    location: aiSearchLocation
    tags: tags
  }
}

// ──────────────────────────────────────────────
// Phase 3: AI Foundry (Account + Project + Model + CapHost)
// ──────────────────────────────────────────────

module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'ai-foundry-${uniqueSuffix}-deployment'
  params: {
    accountName: aiAccountName
    projectName: aiProjectName
    location: aiFoundryLocation
    tags: tags
    storageAccountId: storageAccount.outputs.resourceId
    storageAccountName: storageAccount.outputs.resourceName
    cosmosAccountId: cosmosDb.outputs.resourceId
    cosmosAccountName: cosmosDb.outputs.resourceName
    searchServiceId: aiSearch.outputs.resourceId
    searchServiceName: aiSearch.outputs.resourceName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// ──────────────────────────────────────────────
// Phase 4: RBAC (Deployer + Project MI)
// ──────────────────────────────────────────────

module roleAssignments 'modules/role-assignments.bicep' = {
  name: 'rbac-${uniqueSuffix}-deployment'
  params: {
    principalId: principalId
    projectPrincipalId: aiFoundry.outputs.projectPrincipalId
    aiAccountId: aiFoundry.outputs.accountId
    aiAccountName: aiFoundry.outputs.accountName
    storageAccountId: storageAccount.outputs.resourceId
    storageAccountName: storageAccount.outputs.resourceName
    cosmosAccountId: cosmosDb.outputs.resourceId
    cosmosAccountName: cosmosDb.outputs.resourceName
    searchServiceId: aiSearch.outputs.resourceId
    searchServiceName: aiSearch.outputs.resourceName
  }
}

// ──────────────────────────────────────────────
// Phase 5: Capability Host — Project Level (after RBAC)
// ──────────────────────────────────────────────

module caphostProject 'modules/caphost-project.bicep' = {
  name: 'caphost-project-${uniqueSuffix}-deployment'
  params: {
    accountName: aiFoundry.outputs.accountName
    projectName: aiFoundry.outputs.projectName
  }
  dependsOn: [
    roleAssignments
  ]
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

@description('AI Foundry Project endpoint for the Python agent.')
output projectEndpoint string = aiFoundry.outputs.projectEndpoint

@description('AI Foundry Account name.')
output aiAccountName string = aiFoundry.outputs.accountName

@description('AI Foundry Project name.')
output aiProjectName string = aiFoundry.outputs.projectName

@description('Resource group name.')
output resourceGroupName string = resourceGroup().name
