@description('The name of the resource.')
param eventGridName string

@description('The location of the resource.')
param location string

@description('Object containing resource tags.')
param tags object = {}

@description('Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = true

@description('The user assigned ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Source for the system topic.')
param source string

@description('Topic type for the system topic. Defaults to StorageAccount.')
param topicType string = 'Microsoft.Storage.StorageAccounts'

@description('Event Grid subscriptions to create.')
@metadata({
  name: 'Event Grid subscription name.'
  endpointType: 'Endpoint type, e.g. EventHub, StorageQueue etc. Accepted values found here: https://docs.microsoft.com/en-us/azure/templates/microsoft.eventgrid/systemtopics/eventsubscriptions?tabs=bicep#eventsubscriptiondestination.'
  properties: 'Object containing properties for the event subscription. Accepted values found here: https://docs.microsoft.com/en-us/azure/templates/microsoft.eventgrid/systemtopics/eventsubscriptions?tabs=bicep#deliverywithresourceidentity.'
  resourceId: 'The Azure Resource ID of the resource that is the destination of an event subscription.'
  eventSchema: 'The event delivery schema for the event subscription. Accepted values: "CloudEventSchemaV1_0", "CustomInputSchema", "EventGridSchema".'
  filterEventTypes: 'Array containing a list of applicable event types that need to be part of the event subscription. If it is desired to subscribe to all default event types, set to null.'
})
param eventSubscriptions array = []

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Specify the type of resource lock.')
param resourcelock string = 'NotSpecified'

@description('Enable diagnostic logs.')
param enableDiagnostics bool = false

@allowed([
  'allLogs'
  'audit'
])
@description('Specify the type of diagnostic logs to monitor.')
param diagnosticLogGroup string = 'allLogs'

@description('Storage account resource id. Only required if enableDiagnostics is set to true.')
param diagnosticStorageAccountId string = ''

@description('Log analytics workspace resource id. Only required if enableDiagnostics is set to true.')
param diagnosticLogAnalyticsWorkspaceId string = ''

@description('Event hub authorization rule for the Event Hubs namespace. Only required if enableDiagnostics is set to true.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Event hub name. Only required if enableDiagnostics is set to true.')
param diagnosticEventHubName string = ''

var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')
var identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
} : null
var lockName = toLower('${eventGrid.name}-${resourcelock}-lck')
var diagnosticsName = '${eventGrid.name}-dgs'

resource eventGrid 'Microsoft.EventGrid/systemTopics@2021-12-01' = {
  name: eventGridName
  location: location
  tags: tags
  identity: identity
  properties: {
    source: source
    topicType: topicType
  }
}

resource eventGridSubscriptionStorage 'Microsoft.Storage/storageAccounts@2021-08-01' existing = [for sub in eventSubscriptions: if (sub.endpointType == 'StorageQueue') {
  name: last(split(sub.resourceId, '/'))
}]

resource role 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [for (sub, index) in eventSubscriptions: if (sub.endpointType == 'StorageQueue') {
  scope: eventGridSubscriptionStorage[index]
  name: guid(eventGrid.name)
  properties: {
    principalId: eventGrid.identity.principalId
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/c6a89b2d-59bc-44d0-9896-0f6e12d7b80a'
  }
}]

resource eventGridSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2021-12-01' = [for sub in eventSubscriptions: {
  parent: eventGrid
  name: sub.name
  properties: {
    deliveryWithResourceIdentity: {
      identity: identity
      destination: {
        endpointType: sub.endpointType
        properties: sub.properties
      }
    }
    eventDeliverySchema: sub.eventSchema
    filter: {
      includedEventTypes: sub.filterEventTypes
    }
  }
}]

resource lock 'Microsoft.Authorization/locks@2017-04-01' = if (resourcelock != 'NotSpecified') {
  scope: eventGrid
  name: lockName
  properties: {
    level: resourcelock
    notes: (resourcelock == 'CanNotDelete') ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: eventGrid
  name: diagnosticsName
  properties: {
    workspaceId: empty(diagnosticLogAnalyticsWorkspaceId) ? null : diagnosticLogAnalyticsWorkspaceId
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    eventHubAuthorizationRuleId: empty(diagnosticEventHubAuthorizationRuleId) ? null : diagnosticEventHubAuthorizationRuleId
    eventHubName: empty(diagnosticEventHubName) ? null : diagnosticEventHubName
    logs: [
      {
        categoryGroup: diagnosticLogGroup
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

output name string = eventGrid.name
output id string = eventGrid.id
