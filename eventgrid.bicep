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

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Specify the type of resource lock.')
param resourcelock string = 'NotSpecified'

@description('Enable diagnostic logs')
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
