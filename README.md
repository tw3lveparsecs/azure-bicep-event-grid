# Event Grid
This module creates an Azure Event Grid System Topic.

You can optionally configure managed identities, diagnostics and resource lock.

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

