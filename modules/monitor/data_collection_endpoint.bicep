param deploymentParams object
param dceParams object
param tags object = resourceGroup().tags
param osKind string


resource r_lin_dce 'Microsoft.Insights/dataCollectionEndpoints@2021-04-01' = {
  name: '${dceParams.endpointNamePrefix}-Dce-${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  tags: tags
  kind: osKind
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

output linDataCollectionEndpointId string = r_lin_dce.id
output linDataCollectionEndpointName string = r_lin_dce.name
