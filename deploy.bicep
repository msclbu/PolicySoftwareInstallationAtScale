param storageAccountName string
param automationAccountName string
param location string
param subscriptionId string
param storageAccountResourceGroupName string
param resourceGroupName string
param mgId string

var modules = [
  {
    name: 'Az.Accounts'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/az.accounts.2.10.3.nupkg'
  }
  {
    name: 'Az.Resources'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/az.resources.6.4.1.nupkg'
  }
  {
    name: 'Az.Storage'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/az.storage.5.1.0.nupkg'
  }
  {
    name: 'Az.Compute'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/az.compute.5.1.1.nupkg'
  }
]

var automationVariables = [
  {
    name: 'StorageAccountName'
    value: storageAccountName
  }
  {
    name: 'ResourceGroupName'
    value: storageAccountResourceGroupName
  }
]


resource aa 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: automationAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource aavars 'Microsoft.Automation/automationAccounts/variables@2020-01-13-preview' = [for j in automationVariables: {
  name: '${automationAccountName}/${j.name}'
  properties: {
    value: '"${j.value}"'
    isEncrypted: true
  }
  dependsOn: [
    aa
  ]
}]

resource perm1 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(automationAccountName)
  properties: {
    principalId: aa.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '9980e02c-c2be-4d73-94e8-173b1dc7cf3c')
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    aa
  ]
}

@batchSize(1)
resource mods 'Microsoft.Automation/automationAccounts/modules@2015-10-31' = [for i in modules: {
  name: '${automationAccountName}/${i.name}'
  location: location
  properties: {
    contentLink: {
      uri: i.url
    }
  }
  dependsOn: [
    aa
  ]
}]


resource systopic 'Microsoft.EventGrid/systemTopics@2020-10-15-preview' = {
  name: 'PolicyStateChanges'
  location: 'global'
  properties: {
    topicType: 'Microsoft.PolicyInsights.PolicyStates'
    source: mgId
  }
}


module nestedStorageTemplate './AutomationAccountStorage_Nested.bicep' = {
  name: 'nestedStorageTemplate'
  scope: resourceGroup(subscriptionId, 'Shared-RG')
  params: {
    aaNameNested: reference(resourceId('Microsoft.Automation/automationAccounts', automationAccountName), '2022-08-08', 'Full')
    storageName: storageAccountName
  }
  dependsOn: [
    aa
  ]
}
