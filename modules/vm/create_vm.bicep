param deploymentParams object
param tags object = resourceGroup().tags

param saName string
param blobContainerName string
param saPrimaryEndpointsBlob string

param queueName string
param appConfigName string

param linDataCollectionEndpointId string
param storeEventsDcrId string
param automationEventsDcrId string

param vmParams object
param vnetName string
param vmName string = '${vmParams.vmNamePrefix}-${deploymentParams.global_uniqueness}'
param dnsLabelPrefix string = toLower('${vmParams.vmNamePrefix}-${deploymentParams.global_uniqueness}-${uniqueString(resourceGroup().id, vmName)}')
param publicIpName string = '${vmParams.vmNamePrefix}-${deploymentParams.global_uniqueness}-PublicIp'

// var userDataScript = base64(loadTextContent('./bootstrap_scripts/deploy_app.sh'))
var userDataScript = loadFileAsBase64('./bootstrap_scripts/deploy_app.sh')

// @description('VM auth')
// @allowed([
//   'sshPublicKey'
//   'password'
// ])
// param authType string = 'password'

var LinuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publickeys: [
      {
        path: '/home/${vmParams.adminUsername}/.ssh/authorized_keys'
        keyData: vmParams.adminPassword
      }
    ]
  }
}

resource r_publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIpName
  location: deploymentParams.location
  tags: tags
  sku: {
    name: vmParams.publicIpSku
  }
  properties: {
    publicIPAllocationMethod: vmParams.publicIPAllocationMethod
    publicIPAddressVersion: 'IPv4'
    deleteOption: 'Delete'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource r_webSg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'webSg'
  location: deploymentParams.location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowInboundSsh'
        properties: {
          priority: 250
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'HTTP'
        properties: {
          priority: 200
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'Outbound_Allow_All'
        properties: {
          priority: 300
          protocol: '*'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'AzureResourceManager'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureResourceManager'
          access: 'Allow'
          priority: 160
          direction: 'Outbound'
        }
      }
      {
        name: 'AzureStorageAccount'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Storage.${deploymentParams.location}'
          access: 'Allow'
          priority: 170
          direction: 'Outbound'
        }
      }
      {
        name: 'AzureFrontDoor'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureFrontDoor.FrontEnd'
          access: 'Allow'
          priority: 180
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Create NIC for the VM
resource r_nic_01 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: '${vmName}-Nic-01'
  location: deploymentParams.location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, vmParams.vmSubnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: r_publicIp.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: r_webSg.id
    }
  }
}

// Create User-Assigned Identity
resource r_userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${vmName}_${deploymentParams.global_uniqueness}_Identity'
  location: deploymentParams.location
  tags: tags
}


// Add permissions to the custom identity to write to the blob storage
// Azure Built-In Roles Ref: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
param blobOwnerRoleId string = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'

var blobPermsConditionStr= '((!(ActionMatches{\'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read\'}) AND !(ActionMatches{\'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write\'}) ) OR (@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals \'${blobContainerName}\'))'

resource r_blob_Ref 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' existing = {
  name: '${saName}/default/${blobContainerName}'
}


// Refined Scope with conditions
// https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?pivots=deployment-language-bicep

resource r_attachBlobOwnerPermsToRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('r_attachBlobOwnerPermsToRole', r_userManagedIdentity.id, blobOwnerRoleId)
  scope: r_blob_Ref
  properties: {
    description: 'Blob Owner Permission to ResourceGroup scope'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', blobOwnerRoleId)
    principalId: r_userManagedIdentity.properties.principalId
    conditionVersion: '2.0'
    condition: blobPermsConditionStr
    principalType: 'ServicePrincipal'
    // https://learn.microsoft.com/en-us/azure/role-based-access-control/troubleshooting?tabs=bicep#symptom---assigning-a-role-to-a-new-principal-sometimes-fails
  }
}


resource r_q_Ref 'Microsoft.Storage/storageAccounts/queueServices/queues@2022-09-01' existing = {
  name: '${saName}/default/${queueName}'
}

param qContributorRoleId string = '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
var qPermsConditionStr = '((!(ActionMatches{\'Microsoft.Storage/storageAccounts/queueServices/queues/messages/delete\'}) AND !(ActionMatches{\'Microsoft.Storage/storageAccounts/queueServices/queues/messages/read\'}) AND !(ActionMatches{\'Microsoft.Storage/storageAccounts/queueServices/queues/messages/write\'}) AND !(ActionMatches{\'Microsoft.Storage/storageAccounts/queueServices/queues/messages/process/action\'} ) ) OR (@Resource[Microsoft.Storage/storageAccounts/queueServices/queues:name] StringEquals \'${queueName}\'))'

resource r_attachQContributorPermsToRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('r_attachQContributorPermsToRole', r_userManagedIdentity.id, qContributorRoleId)
  scope: r_q_Ref
  properties: {
    description: 'Queue Contributor Permission to ResourceGroup scope'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', qContributorRoleId)
    principalId: r_userManagedIdentity.properties.principalId
    conditionVersion: '2.0'
    condition: qPermsConditionStr
    principalType: 'ServicePrincipal'
    // https://learn.microsoft.com/en-us/azure/role-based-access-control/troubleshooting?tabs=bicep#symptom---assigning-a-role-to-a-new-principal-sometimes-fails
  }
}


// Get App Config Reference
resource r_appConfig_Ref 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appConfigName
}
// App Config Owner
param appConfigOwnerRoleId string = '5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b'
// var appConfigConditionStr = '((!(ActionMatches{\'Microsoft.AppConfiguration/configurationStores/*/read\'}) AND !(ActionMatches{\'Microsoft.AppConfiguration/configurationStores/*/write\'}) AND !(ActionMatches{\'Microsoft.AppConfiguration/configurationStores/*/delete\'}) AND !(ActionMatches{\'Microsoft.AppConfiguration/configurationStores/*/action\'} ) ) OR (@Resource[Microsoft.AppConfiguration/configurationStores/*]))'
// CONDITIONS LIMITATIONS - https://learn.microsoft.com/en-us/azure/role-based-access-control/conditions-format#actions
resource r_attachappConfigOwnerPermsToRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('r_attachappConfigOwnerPermsToRole', r_userManagedIdentity.id, appConfigOwnerRoleId)
  scope: r_appConfig_Ref
  properties: {
    description: 'App Configuration Owner Permission'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', appConfigOwnerRoleId)
    principalId: r_userManagedIdentity.properties.principalId
    // conditionVersion: '2.0'
    // condition: appConfigConditionStr
    principalType: 'ServicePrincipal'
  }
}


resource r_vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: deploymentParams.location
  tags: tags
  identity: {
    // type: 'SystemAssigned'
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${r_userManagedIdentity.id}': {}
    }
  }
  // zones: [
  //   '3'
  // ]
  properties: {
    hardwareProfile: {
      vmSize: vmParams.vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmParams.adminUsername
      adminPassword: vmParams.adminPassword.secureString
      linuxConfiguration: ((vmParams.authType == 'password') ? null : LinuxConfiguration)
    }
    storageProfile: {
      imageReference: ((vmParams.isUbuntu == true) ? ({
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }) : ({
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '91-gen2'
        version: 'latest'
      }))
      osDisk: {
        createOption: 'FromImage'
        name: '${vmName}_osDisk'
        caching: 'ReadWrite'
        deleteOption: 'Delete'
        diskSizeGB: 128
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          createOption: 'Empty'
          name: '${vmName}-DataDisk'
          caching: 'ReadWrite'
          deleteOption: 'Delete'
          lun: 13
          diskSizeGB: 2
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
            // storageAccountType: 'PremiumV2_LRS' // Apparently needs zones to be defined and AZURE capacity issues - ^.^
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: r_nic_01.id
        }
      ]
    }
    securityProfile: {
      // encryptionAtHost: true
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
        storageUri: saPrimaryEndpointsBlob
      }
    }
    userData: userDataScript
  }
}

// INSTALL Azure Monitor Agent
resource AzureMonitorLinuxAgent 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = if (vmParams.isLinux) {
  parent: r_vm
  name: 'AzureMonitorLinuxAgent'
  location: deploymentParams.location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    enableAutomaticUpgrade: true
    autoUpgradeMinorVersion: true
    typeHandlerVersion: '1.25'
    settings: {
      'identifier-name': 'mi_res_id' // Has to be this value
      // 'identifier-value': r_vm.identity.principalId
      'identifier-value': r_userManagedIdentity.id
    }
  }
}

// Associate Data Collection Endpoint to VM
// Apparently you cannot name this resource and also it cannot be clubbed with DCR association
resource r_associateDce_To_Vm 'Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview' = {
  name: 'configurationAccessEndpoint'
  scope: r_vm
  properties: {
    dataCollectionEndpointId: linDataCollectionEndpointId
    // dataCollectionRuleId: storeEventsDcrId
    description: 'Send Custom logs to DCR'
  }
}
resource r_associatestoreEventsDcr_To_Vm 'Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview' = {
  name: '${vmName}_storeEventsDcr_${deploymentParams.global_uniqueness}'
  scope: r_vm
  properties: {
    // dataCollectionEndpointId: linDataCollectionEndpointId
    dataCollectionRuleId: storeEventsDcrId
    description: 'Send Application Logs to DCR'
  }
}
resource r_associateautomationEventsDcr_To_Vm 'Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview' = {
  name: '${vmName}_automationEvents_${deploymentParams.global_uniqueness}'
  scope: r_vm
  properties: {
    // dataCollectionEndpointId: linDataCollectionEndpointId
    dataCollectionRuleId: automationEventsDcrId
    description: 'Send Automation Logs to DCR'
  }
}

resource windowsAgent 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = if (vmParams.isWindows) {
  name: 'AzureMonitorWindowsAgent'
  parent: r_vm
  location: deploymentParams.location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

output webGenHostName string = r_publicIp.properties.dnsSettings.fqdn
output adminUsername string = vmParams.adminUsername
output sshCommand string = 'ssh ${vmParams.adminUsername}@${r_publicIp.properties.dnsSettings.fqdn}'
output webGenHostId string = r_vm.id
output webGenHostPrivateIP string = r_nic_01.properties.ipConfigurations[0].properties.privateIPAddress
output userManagedIdentityId string = r_userManagedIdentity.id
output qPermsConditionStr string = qPermsConditionStr

