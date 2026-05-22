using './main.bicep'

param environment = readEnvironmentVariable('AZURE_ENV_NAME', 'demo')
param location = readEnvironmentVariable('AZURE_LOCATION', 'eastus2')
param projectName = 'foundryagent'
param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
param aiFoundryLocation = readEnvironmentVariable('AZURE_AI_FOUNDRY_LOCATION', 'swedencentral')
param aiSearchLocation = readEnvironmentVariable('AZURE_AI_SEARCH_LOCATION', 'westus3')
