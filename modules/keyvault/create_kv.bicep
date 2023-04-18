param deploymentParams object
param kvNamePrefix string
param tags object = resourceGroup().tags

param skuName string = 'standard'

resource r_kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: '${kvNamePrefix}-kv-${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  tags: tags
  properties: {
    accessPolicies:[]
    enableRbacAuthorization: false
    enableSoftDelete: false
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    tenantId: subscription().tenantId
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

output kvName string = r_kv.name

