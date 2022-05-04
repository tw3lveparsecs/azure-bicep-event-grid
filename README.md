# Event Grid
This module creates an Azure Event Grid System Topic.

You can optionally configure event subscriptions, managed identities, diagnostics and resource lock.

## Usage

### Example 1 - Event Grid with storage account source
```bicep
param deploymentName string = 'eg${utcNow()}'
param location string = resourceGroup().location

module eventHub 'eventgrid.bicep' = {
  name: deploymentName
  params: {
    eventGridName: 'myEventGridName'
    location: location
    source: 'myStorageAccountResourceId'    
  }
}
```

### Example 2 - Event Grid with diagnostics and resource lock
```bicep
param deploymentName string = 'eg${utcNow()}'
param location string = resourceGroup().location

module eventHub 'eventgrid.bicep' = {
  name: deploymentName
  params: {
    eventGridName: 'myEventGridName'
    location: location
    source: 'myResourceGroupResourceId'
    topicType: 'Microsoft.Resources.ResourceGroups'
    resourcelock: 'CanNotDelete'
    enableDiagnostics: true    
    diagnosticLogAnalyticsWorkspaceId: 'myLogAnalyticsWorkspaceResourceId'
  }
}
```

### Example 3 - Event Grid with event subscription
```bicep
param deploymentName string = 'eg${utcNow()}'
param location string = resourceGroup().location

module eventHub 'eventgrid.bicep' = {
  name: deploymentName
  params: {
    eventGridName: 'myEventGridName'
    location: location
    source: 'myStorageAccountResourceId'
    eventSubscriptions: [
      {
        name: 'myEventSubscriptionName'
        endpointType: 'StorageQueue'
        properties: {
          queueMessageTimeToLiveInSeconds: 300
          queueName: 'myStorageQueueName'
          resourceId: 'myStorageAccountResourceId'
        }
        resourceId: 'myStorageAccountResourceId'
        eventSchema: 'EventGridSchema'
        filterEventTypes: [
          'Microsoft.Storage.BlobCreated'
          'Microsoft.Storage.BlobDeleted'
        ]
      }
    ]
  }
}
```

