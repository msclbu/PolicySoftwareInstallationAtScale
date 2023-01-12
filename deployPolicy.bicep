param policyDefinitionIdWindows string
param policyDefinitionIdLinux string
param location string

targetScope = 'managementGroup'

var policyGuestConfigDefinitionId = '/providers/Microsoft.Authorization/policySetDefinitions/12794019-7a00-42cf-95c2-882eed337cc8'


resource gcpol 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: uniqueString('GC')
  location: location
  properties: {
    policyDefinitionId: policyGuestConfigDefinitionId
    displayName: 'Deploy Guest Configuration'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource softwarepolLinux 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: uniqueString('GitLinux')
  location: location
  properties: {
    policyDefinitionId: policyDefinitionIdLinux
    displayName: 'Audit Linux virtual machines via tags without Git installed'
    parameters: {
      ApplicationName: {
        value: 'git'
      }
    }
  }
}


resource softwarepolWin 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: uniqueString('PowershellWindows')
  location: location
  properties: {
    policyDefinitionId: policyDefinitionIdWindows
    displayName: 'Audit Windows virtual machines via tags without Powershell installed'
    parameters: {
      installedApplication: {
        value: 'PowerShell 7-x64'
      }
    }
  }
}


output assignmentIdWin string = softwarepolWin.id
output assignmentIdLinux string = softwarepolLinux.id
