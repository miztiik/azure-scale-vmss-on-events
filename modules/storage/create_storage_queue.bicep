param deploymentParams object
param storageQueueParams object
param storageAccountName string
param appConfigName string
param tags object = resourceGroup().tags

// Get reference of SA
resource r_sa 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
}


resource r_qSvcs 'Microsoft.Storage/storageAccounts/queueServices@2021-04-01' = {
  name: 'default'
  parent: r_sa
  properties: {
    }
  }

resource r_storage_q 'Microsoft.Storage/storageAccounts/queueServices/queues@2022-09-01' = {
  parent: r_qSvcs
  name: '${storageQueueParams.queueNamePrefix}-q-${deploymentParams.global_uniqueness}'
  properties: {
    metadata: {}
  }
}

// Get App Config Reference
resource r_appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appConfigName
}

resource r_q_name_Kv 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = {
  parent: r_appConfig
  name: 'queueName'
  properties: {
    value: r_storage_q.name
    contentType: 'text/plain'
    tags: tags
  }
}

output queueName string = r_storage_q.name
output queueId string = r_storage_q.id
