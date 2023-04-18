param deploymentParams object
param storageAccountParams object
param storageAccountName string

param appConfigName string
param tags object = resourceGroup().tags

// Get reference of SA
resource r_sa 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
}

// Create a blob storage container in the storage account
resource r_blobSvc 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: r_sa
  name: 'default'
}

resource r_blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  parent: r_blobSvc
  name: '${storageAccountParams.blobNamePrefix}-blob-${deploymentParams.global_uniqueness}'
  properties: {
    publicAccess: 'None'
  }
}

// Store the storage account name and primary endpoint in the App Config
resource r_appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appConfigName
}

resource r_q_name_Kv 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = {
  parent: r_appConfig
  name: 'blobName'
  properties: {
    value: r_blobContainer.name
    contentType: 'text/plain'
    tags: tags
  }
}


output blobContainerId string = r_blobContainer.id
output blobContainerName string = r_blobContainer.name
