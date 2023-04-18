param virtualMachineScaleSets_testscale_name string = 'testscale'
param virtualNetworks_dataGenSwarm_Vnet_001_externalid string = '/subscriptions/1ac6fdb8-61a9-4e86-a871-1baff37cd9e3/resourceGroups/Miztiik_Enterprises_scale_vmss_on_events_001/providers/Microsoft.Network/virtualNetworks/dataGenSwarm_Vnet_001'
param loadBalancers_lb_externalid string = '/subscriptions/1ac6fdb8-61a9-4e86-a871-1baff37cd9e3/resourceGroups/Miztiik_Enterprises_scale_vmss_on_events_001/providers/Microsoft.Network/loadBalancers/lb'
param networkSecurityGroups_basicNsgdataGenSwarm_Vnet_001_nic01_externalid string = '/subscriptions/1ac6fdb8-61a9-4e86-a871-1baff37cd9e3/resourceGroups/Miztiik_Enterprises_scale_vmss_on_events_001/providers/Microsoft.Network/networkSecurityGroups/basicNsgdataGenSwarm_Vnet_001-nic01'

resource virtualMachineScaleSets_testscale_name_resource 'Microsoft.Compute/virtualMachineScaleSets@2022-11-01' = {
  name: virtualMachineScaleSets_testscale_name
  location: 'westeurope'
  sku: {
    name: 'Standard_D2lds_v5'
    tier: 'Standard'
    capacity: 1
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    singlePlacementGroup: false
    orchestrationMode: 'Flexible'
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: virtualMachineScaleSets_testscale_name
        adminUsername: 'miztiik'
        linuxConfiguration: {
          disablePasswordAuthentication: false
          provisionVMAgent: true
          patchSettings: {
            patchMode: 'ImageDefault'
            assessmentMode: 'ImageDefault'
          }
          enableVMAgentPlatformUpdates: false
        }
        secrets: []
        allowExtensionOperations: true
        requireGuestProvisionSignal: true
      }
      storageProfile: {
        osDisk: {
          osType: 'Linux'
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          deleteOption: 'Delete'
          diskSizeGB: 30
        }
        imageReference: {
          publisher: 'canonical'
          offer: '0001-com-ubuntu-server-focal'
          sku: '20_04-lts-gen2'
          version: 'latest'
        }
      }
      networkProfile: {
        networkApiVersion: '2020-11-01'
        networkInterfaceConfigurations: [
          {
            name: 'dataGenSwarm_Vnet_001-nic01'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              disableTcpStateTracking: false
              enableIPForwarding: false
              deleteOption: 'Delete'
              ipConfigurations: [
                {
                  name: 'dataGenSwarm_Vnet_001-nic01-defaultIpConfiguration'
                  properties: {
                    privateIPAddressVersion: 'IPv4'
                    subnet: {
                      id: '${virtualNetworks_dataGenSwarm_Vnet_001_externalid}/subnets/webSubnet01'
                    }
                    primary: true
                    publicIPAddressConfiguration: {
                      name: 'publicIp-dataGenSwarm_Vnet_001-nic01'
                      properties: {
                        idleTimeoutInMinutes: 15
                        ipTags: []
                        publicIPAddressVersion: 'IPv4'
                      }
                    }
                    applicationSecurityGroups: []
                    loadBalancerBackendAddressPools: [
                      {
                        id: '${loadBalancers_lb_externalid}/backendAddressPools/bepool'
                      }
                    ]
                    applicationGatewayBackendAddressPools: []
                  }
                }
              ]
              networkSecurityGroup: {
                id: networkSecurityGroups_basicNsgdataGenSwarm_Vnet_001_nic01_externalid
              }
              dnsSettings: {
                dnsServers: []
              }
            }
          }
        ]
      }
      extensionProfile: {
        extensions: []
      }
    }
    zoneBalance: false
    platformFaultDomainCount: 1
    constrainedMaximumCapacity: false
  }
}

resource virtualMachineScaleSets_testscale_name_virtualMachineScaleSets_testscale_name_9c689dd7 'Microsoft.Compute/virtualMachineScaleSets/virtualMachines@2022-11-01' = {
  parent: virtualMachineScaleSets_testscale_name_resource
  name: '${virtualMachineScaleSets_testscale_name}_9c689dd7'
  location: 'westeurope'
  zones: [
    '1'
  ]
}