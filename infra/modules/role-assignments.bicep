// RBAC Role Assignments — Deployer + Project Managed Identity

@description('Principal ID of the deploying user (from AZURE_PRINCIPAL_ID).')
param principalId string

@description('Principal ID of the AI Foundry Project system-assigned managed identity.')
param projectPrincipalId string

@description('Resource ID of the AI Foundry Account.')
param aiAccountId string

@description('Name of the AI Foundry Account.')
param aiAccountName string

@description('Resource ID of the Storage Account.')
param storageAccountId string

@description('Name of the Storage Account.')
param storageAccountName string

@description('Resource ID of the Cosmos DB Account.')
param cosmosAccountId string

@description('Name of the Cosmos DB Account.')
param cosmosAccountName string

@description('Resource ID of the AI Search service.')
param searchServiceId string

@description('Name of the AI Search service.')
param searchServiceName string

// ──────────────────────────────────────────────
// Existing resources (scoping role assignments)
// ──────────────────────────────────────────────

resource aiAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: aiAccountName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' existing = {
  name: cosmosAccountName
}

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' existing = {
  name: searchServiceName
}

// ──────────────────────────────────────────────
// Role definitions
// ──────────────────────────────────────────────

var azureAiOwner = 'b78c5d69-af96-48a3-bf8d-a8b4d589de94'
var storageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var cosmosDbAccountReader = 'fbdf93bf-df7d-467e-a4d2-9458aa1360c8'
var cosmosDbOperator = '230815da-be43-4aae-9cb4-875f7bd000aa'
var searchIndexDataContributor = '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
var searchServiceContributor = '7ca78c08-252a-4471-8644-bb5ff32d4ba0'

// ──────────────────────────────────────────────
// Deployer Roles
// ──────────────────────────────────────────────

resource deployerAiOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(aiAccountId, principalId, azureAiOwner)
  scope: aiAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureAiOwner)
    principalId: principalId
    principalType: 'User'
  }
}

resource deployerStorageBlob 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(storageAccountId, principalId, storageBlobDataContributor)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributor)
    principalId: principalId
    principalType: 'User'
  }
}

// ──────────────────────────────────────────────
// Project MI Roles — Storage
// ──────────────────────────────────────────────

resource projectStorageBlob 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountId, projectPrincipalId, storageBlobDataContributor)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributor)
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ──────────────────────────────────────────────
// Project MI Roles — Cosmos DB
// ──────────────────────────────────────────────

resource projectCosmosReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosAccountId, projectPrincipalId, cosmosDbAccountReader)
  scope: cosmosAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cosmosDbAccountReader)
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource projectCosmosOperator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosAccountId, projectPrincipalId, cosmosDbOperator)
  scope: cosmosAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cosmosDbOperator)
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ──────────────────────────────────────────────
// Project MI Roles — AI Search
// ──────────────────────────────────────────────

resource projectSearchIndexContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchServiceId, projectPrincipalId, searchIndexDataContributor)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataContributor)
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource projectSearchServiceContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchServiceId, projectPrincipalId, searchServiceContributor)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchServiceContributor)
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
  }
}
