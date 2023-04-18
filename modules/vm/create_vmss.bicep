param deploymentParams object
param tags object = resourceGroup().tags
param userManagedIdentityId string
param appConfigName string

// param vmSku string = 'Standard_DS2_v2' 
param vmSku string = 'Standard_D2lds_v5' 
param desiredInstanceCount int = 1
param singlePlacementGroup bool = false
param platformFaultDomainCount int = 1

param vmParams object
param vnetName string
param vmName string = '${vmParams.vmNamePrefix}-${deploymentParams.global_uniqueness}'


var userDataScript = loadFileAsBase64('./bootstrap_scripts/deploy_app.sh')
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
  provisionVMAgent: true
    patchSettings: {
      patchMode: 'AutomaticByPlatform'
      assessmentMode: 'AutomaticByPlatform'
    }
}


resource r_vmScaleSet 'Microsoft.Compute/virtualMachineScaleSets@2022-11-01' = {
  name: '${vmName}_${deploymentParams.global_uniqueness}_Vmss'
  location: deploymentParams.location
  tags: tags
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: desiredInstanceCount
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userManagedIdentityId}': {}
    }
  }
  properties: {
    zoneBalance: true
    // constrainedMaximumCapacity: true
    // orchestrationMode: 'Flexible'
    platformFaultDomainCount: platformFaultDomainCount
    overprovision: false
    singlePlacementGroup: singlePlacementGroup
    // automaticRepairsPolicy: {
    //   enabled: true
    //   gracePeriod: 'PT10M'
    //   repairAction: 'Replace'
    // }
    upgradePolicy: {
      mode: 'Automatic'
      automaticOSUpgradePolicy: {
        enableAutomaticOSUpgrade: false
        useRollingUpgradePolicy: true
      }
      rollingUpgradePolicy: {
        maxBatchInstancePercent: 20
        maxUnhealthyInstancePercent: 20
        maxUnhealthyUpgradedInstancePercent: 20
        pauseTimeBetweenBatches: 'PT0S'
        prioritizeUnhealthyInstances: true
      }
    }
    virtualMachineProfile: {
      userData: userDataScript
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: false
        }
      }
      osProfile: {
        computerNamePrefix: vmName
        allowExtensionOperations: true
        adminUsername: vmParams.adminUsername
        adminPassword: vmParams.adminPassword.secureString
        linuxConfiguration: ((vmParams.authType == 'password') ? null : LinuxConfiguration)
      }
      storageProfile: {
        osDisk: {
          osType: 'Linux'
          createOption: 'FromImage'
          caching: 'ReadWrite'
          diskSizeGB: 48
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
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
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${vmName}_vmssNic'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              enableIPForwarding: false
              ipConfigurations: [
                {
                  name: '${vmName}_vmssIpConfig'
                  properties: {
                    primary: true
                    privateIPAddressVersion: 'IPv4'
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, vmParams.vmSubnetName)
                    }
                    publicIPAddressConfiguration: {
                      name: '${vmName}_vmssPublicIP'
                      properties: {
                        idleTimeoutInMinutes: 15
                        ipTags: []
                        publicIPAddressVersion: 'IPv4'
                      }
                    }
                    // loadBalancerBackendAddressPools: [
                    //   {
                    //     id: '${loadBalancers_lb_externalid}/backendAddressPools/bepool'
                    //   }
                    // ]
                  }
                }
              ]
              // networkSecurityGroup: {
              //   id: networkSecurityGroups_basicNsgdataGenSwarm_Vnet_001_nic01_externalid
              // }
              dnsSettings: {
                dnsServers: []
              }
            }
          }
        ]
      }
    }
  }
}


// INSTALL Azure Monitor Agent
resource r_installAzureMonitorLinuxAgent 'Microsoft.Compute/virtualMachineScaleSets/extensions@2021-07-01' = {
  parent: r_vmScaleSet
  name: 'AzureMonitorLinuxAgent'
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    enableAutomaticUpgrade: true
    autoUpgradeMinorVersion: true
    typeHandlerVersion: '1.25'
    settings: {
      'identifier-name': 'mi_res_id' // Has to be this value
      'identifier-value': userManagedIdentityId
    }
  }
}


// Setup the Consumer script as VM Extension
resource r_setupCustomScript 'Microsoft.Compute/virtualMachineScaleSets/extensions@2022-11-01' = {
  name: 'installMiztiikCustomScriptForConsumer'
  parent: r_vmScaleSet
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    autoUpgradeMinorVersion: true
    forceUpdateTag: '2'
    settings: {
      fileUris: ['hhttps://raw.githubusercontent.com/miztiik/azure-scale-vmss-on-events/main/app/az_consumer_for_queues.py']
      commandToExecute: '#!/bin/bash; export APP_CONFIG_NAME=${appConfigName}; python3 az_consumer_for_queues.py'
    }
    suppressFailures: false
    typeHandlerVersion: '2.1'
  }
}
