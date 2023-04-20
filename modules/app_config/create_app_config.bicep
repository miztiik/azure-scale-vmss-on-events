param deploymentParams object
param appConfigParams object
param tags object = resourceGroup().tags

param addRandom string = toLower(substring(uniqueString(resourceGroup().id), 0, 6))

resource r_appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: '${appConfigParams.appConfigNamePrefix}-config-${addRandom}-${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  tags: tags
  sku: {
    name: appConfigParams.appConfigSku
  }
}


output appConfigName string = r_appConfig.name
