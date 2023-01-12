
@secure()
param uriWin string
@secure()
param uriLinux string
param policyAssignmentIdLinux string
param policyAssignmentIdWin string
param topicName string


resource esubWin 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2020-10-15-preview' = {
    name: '${topicName}/PolicyChangesWin'
    properties: {
      destination: {
        endpointType: 'WebHook'
        properties: {
          endpointUrl: uriWin
        }
      }
      eventDeliverySchema: 'EventGridSchema'
      filter: {
        includedEventTypes: [
          'Microsoft.PolicyInsights.PolicyStateChanged'
          'Microsoft.PolicyInsights.PolicyStateCreated'
        ]
        advancedFilters: [
          {
            operatorType: 'StringContains'
            key: 'data.policyAssignmentId'
            values: [
              policyAssignmentIdWin
            ]
          }
          {
            operatorType: 'StringBeginsWith'
            key: 'data.complianceState'
            values: [
              'NonCompliant'
            ]
          }
        ]
      }
    }
  }

  resource esubLinux 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2020-10-15-preview' = {
    name: '${topicName}/PolicyChangesLinux'
    properties: {
      destination: {
        endpointType: 'WebHook'
        properties: {
          endpointUrl: uriLinux
        }
      }
      eventDeliverySchema: 'EventGridSchema'
      filter: {
        includedEventTypes: [
          'Microsoft.PolicyInsights.PolicyStateChanged'
          'Microsoft.PolicyInsights.PolicyStateCreated'
        ]
        advancedFilters: [
          {
            operatorType: 'StringContains'
            key: 'data.policyAssignmentId'
            values: [
              policyAssignmentIdLinux
            ]
          }
          {
            operatorType: 'StringBeginsWith'
            key: 'data.complianceState'
            values: [
              'NonCompliant'
            ]
          }
        ]
      }
    }
  }
