// Cosmos DB Account — NoSQL API, Serverless (AVM)

@description('Cosmos DB account name.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

// ──────────────────────────────────────────────
// Cosmos DB Account (Serverless)
// ──────────────────────────────────────────────

module cosmosAccount 'br/public:avm/res/document-db/database-account:0.10.0' = {
  name: '${name}-deploy'
  params: {
    name: name
    location: location
    tags: tags
    capabilitiesToAdd: [
      'EnableServerless'
    ]
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    defaultConsistencyLevel: 'Session'
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

@description('Resource ID of the Cosmos DB account.')
output resourceId string = cosmosAccount.outputs.resourceId

@description('Name of the Cosmos DB account.')
output resourceName string = cosmosAccount.outputs.name
