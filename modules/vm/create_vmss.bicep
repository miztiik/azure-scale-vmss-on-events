param deploymentParams object
param tags object = resourceGroup().tags
param userManagedIdentityId string
param appConfigName string

param queueId string

// param vmSku string = 'Standard_DS2_v2' 
param vmSku string = 'Standard_D2lds_v5' 
param desiredInstanceCount int = 1
param singlePlacementGroup bool = false
param platformFaultDomainCount int = 5

param vmParams object
param vnetName string
param vmName string = '${vmParams.vmNamePrefix}-${deploymentParams.global_uniqueness}'

param linDataCollectionEndpointId string
param storeEventsDcrId string
param automationEventsDcrId string


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
    type: 'UserAssigned'
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

//Using VMSS Machines
resource r_vmssMachines 'Microsoft.Compute/virtualMachineScaleSets/virtualMachines@2022-11-01' = {
  name: '0'
  location: deploymentParams.location
  tags: tags
  parent: r_vmScaleSet
  // identity: {
  //   type: 'string'
  //   userAssignedIdentities: {}
  // }

  properties: {
    // hardwareProfile: {
    //   vmSize: 'string'
    //   vmSizeProperties: {
    //     vCPUsAvailable: int
    //     vCPUsPerCore: int
    //   }
    // }
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
    osProfile: {
        // computerNamePrefix: vmName
        computerName: vmName
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
      userData: userDataScript
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
// param forceUpdateTagValue int = dateTimeToEpoch(utcNow())
// resource r_setupCustomScript 'Microsoft.Compute/virtualMachineScaleSets/extensions@2022-11-01' = {
//   name: 'MiztiikAutomation-Q-Consumers'
//   parent: r_vmScaleSet
//   properties: {
//     publisher: 'Microsoft.Azure.Extensions'
//     type: 'CustomScript'
//     autoUpgradeMinorVersion: true
//     forceUpdateTag: string(forceUpdateTagValue)
//     provisionAfterExtensions:[
//       r_installAzureMonitorLinuxAgent.name
//     ]
//     settings: {
//       timestamp: forceUpdateTagValue    
//     }
//     protectedSettings: {
//       fileUris: ['https://raw.githubusercontent.com/miztiik/azure-scale-vmss-on-events/main/app/az_consumer_for_queues.py']
//       commandToExecute: 'export APP_CONFIG_NAME=${appConfigName}; python3 az_consumer_for_queues.py &'
//   }
//     suppressFailures: true
//     typeHandlerVersion: '2.1'
//   }
// }

resource r_setupCustomScript 'Microsoft.Compute/virtualMachineScaleSets/virtualMachines/runCommands@2022-11-01' = {
  name: 'MiztiikAutomation-RunCommand-Q-Consumers'
  parent: r_vmssMachines
  location: deploymentParams.location
  tags: tags
  properties: {
    asyncExecution: true
    source: {
      // commandId: 'string'
      script: 'export APP_CONFIG_NAME=${appConfigName}; python3 /var/azure-scale-vmss-on-events/app/az_consumer_for_queues.py &'
      // scriptUri: 'https://raw.githubusercontent.com/miztiik/azure-scale-vmss-on-events/main/app/az_consumer_for_queues.py'
    }
    timeoutInSeconds: 3600
  }
}

// Associate Data Collection Endpoint to VMSS
// Apparently you cannot name this resource and also it cannot be clubbed with DCR association
resource r_associateDce_To_Vm 'Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview' = {
  name: 'configurationAccessEndpoint'
  scope: r_vmScaleSet
  properties: {
    dataCollectionEndpointId: linDataCollectionEndpointId
    // dataCollectionRuleId: storeEventsDcrId
    description: 'Send Custom logs to DCR'
  }
}

// Associate Store Events DCR to VM
resource r_associatestoreEventsDcr_To_Vm 'Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview' = {
  name: '${r_vmScaleSet.name}_storeEventsDcr_${deploymentParams.global_uniqueness}'
  scope: r_vmScaleSet
  properties: {
    // dataCollectionEndpointId: linDataCollectionEndpointId
    dataCollectionRuleId: storeEventsDcrId
    description: 'Send Application Logs to DCR'
  }
}

// Associate Automation Events DCR to VM
resource r_associateautomationEventsDcr_To_Vm 'Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview' = {
  name: '${r_vmScaleSet.name}_automationEvents_${deploymentParams.global_uniqueness}'
  scope: r_vmScaleSet
  properties: {
    // dataCollectionEndpointId: linDataCollectionEndpointId
    dataCollectionRuleId: automationEventsDcrId
    description: 'Send Automation Logs to DCR'
  }
}



/*
AUTO SCALE POLICIES
*/

resource r_scaleOnQLength 'Microsoft.Insights/autoscaleSettings@2022-10-01' = {
  name: '${r_vmScaleSet.name}_scaleOnQLength_${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  tags: tags
  properties: {
    name: '${r_vmScaleSet.name}_scaleOnQLength_${deploymentParams.global_uniqueness}'
    enabled: true
    predictiveAutoscalePolicy: {
      scaleMode: 'Disabled'
      scaleLookAheadTime: null
    }
    targetResourceUri: r_vmScaleSet.id
    targetResourceLocation: deploymentParams.location
    notifications: []
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: '1'
          maximum: '3'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: r_vmScaleSet.id
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 50
              statistic: 'Average'
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: r_vmScaleSet.id
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
              statistic: 'Average'
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
    /*
    profiles: [
      {
        name: 'Increase Message Consumers to Max 3 when queueLength > 1000'
        capacity: {
          minimum: '1'
          maximum: '3'
          default: '1'
        }
        rules: [
          {
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
            metricTrigger: {
              metricName: 'ApproximateMessageCount'
              metricNamespace: ''
              metricResourceUri: queueId
              operator: 'GreaterThan'
              statistic: 'Average'
              threshold: 1000
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              dimensions: []
              dividePerInstance: false
            }
          }
          {
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
            metricTrigger: {
              metricName: 'ApproximateMessageCount'
              // metricNamespace: 'microsoft.servicebus/namespaces'
              metricNamespace: ''
              metricResourceUri: queueId
              operator: 'LessThan'
              statistic: 'Average'
              threshold: 250
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              dimensions: []
              dividePerInstance: false
            }
          }
        ]
      }       
    ]
    */
    
  }
}
