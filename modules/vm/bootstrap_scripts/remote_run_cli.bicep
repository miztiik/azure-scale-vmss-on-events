
// # Source: https://github.com/NickBerryJr/Working/blob/bfaf2068ebe36cc05ba10e0fedd67c4e05fef697/groundzero/modules/new-rsv.bicep
resource runCLI 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'runCLI'
  location: rsvLocation
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/0c59ce02-f37e-49e5-8128-90bffc9ceee1/resourceGroups/rg-afk-templateSpecs/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mid-iac-uami-01': {}
    }
  }
  properties:{
    azCliVersion: '2.33.1'
    timeout: 'PT10M'
    retentionInterval: 'P1D'
    cleanupPreference: 'OnSuccess'
    forceUpdateTag: currentTime // ensures script will run every time    
    scriptContent: 'az backup vault encryption update --encryption-key-id ${keyId} --mi-user-assigned ${midId} --resource-group ${resourceGroup().name} --name ${rsvName}'
  }
  dependsOn: [
    newRSV
  ]
}
