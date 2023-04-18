param deploymentParams object
param storageAccountParams object
param appConfigName string
param tags object = resourceGroup().tags

// var = uniqStr2 = guid(resourceGroup().id, "asda")
var uniqStr = substring(uniqueString(resourceGroup().id), 0, 6)
var saName = '${storageAccountParams.storageAccountNamePrefix}${uniqStr}${deploymentParams.global_uniqueness}'

resource r_sa 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: saName
  location: deploymentParams.location
  tags: tags
  sku: {
    name: '${storageAccountParams.sku}'
  }
  kind: '${storageAccountParams.kind}'
  properties: {
    minimumTlsVersion: '${storageAccountParams.minimumTlsVersion}'
    allowBlobPublicAccess: storageAccountParams.allowBlobPublicAccess
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// Store the storage account name and primary endpoint in the App Config
resource r_appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appConfigName
}

resource r_q_name_Kv 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = {
  parent: r_appConfig
  name: 'saName'
  properties: {
    value: r_sa.name
    contentType: 'text/plain'
    tags: tags
  }
}


output saName string = r_sa.name
output saPrimaryEndpointsBlob string = r_sa.properties.primaryEndpoints.blob
output saPrimaryEndpoints object = r_sa.properties.primaryEndpoints
