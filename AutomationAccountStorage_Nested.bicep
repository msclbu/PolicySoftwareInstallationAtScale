param aaNameNested object
param storageName string

resource stg 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: storageName
}

var msiPrincipalId = aaNameNested.identity.principalId

var storageAccountContributorRole = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab'
 
resource roleAssignStorage 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aaNameNested.identity.principalId, storageAccountContributorRole, resourceGroup().name)
  scope: stg
  dependsOn: [
    stg
  ]
  properties: {
    roleDefinitionId: storageAccountContributorRole
    principalId: msiPrincipalId
    principalType: 'ServicePrincipal'
  }
}
