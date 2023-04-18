param deploymentParams object
param vnetParams object

param tags object = resourceGroup().tags

param vnetAddPrefixes object = {
  addressPrefixes: [
    '10.0.0.0/16'
  ]
}
param webSubnet01Cidr string = '10.0.0.0/24'
param webSubnet02Cidr string = '10.0.1.0/24'
param appSubnet01Cidr string = '10.0.2.0/24'
param appSubnet02Cidr string = '10.0.3.0/24'
param dbSubnet01Cidr string = '10.0.4.0/24'
param dbSubnet02Cidr string = '10.0.5.0/24'


resource r_vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: '${vnetParams.vnetNamePrefix}_Vnet_${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  tags: tags
  properties: {
    addressSpace: vnetAddPrefixes
  subnets: [
    {
      name: 'webSubnet01'
      properties: {
        addressPrefix: webSubnet01Cidr
      }
    }
    {
      name: 'webSubnet02'
      properties: {
        addressPrefix: webSubnet02Cidr
      }
    }
    {
      name: 'appSubnet01'
      properties: {
        addressPrefix: appSubnet01Cidr
      }
    }
    {
      name: 'appSubnet02'
      properties: {
        addressPrefix: appSubnet02Cidr
      }
    }
    {
      name: 'dbSubnet01'
      properties: {
        addressPrefix: dbSubnet01Cidr
      }
    }
    {
      name: 'dbSubnet02'
      properties: {
        addressPrefix: dbSubnet02Cidr
      }
    }
  ]
}
}

// resource ng 'Microsoft.Network/natGateways@2021-03-01' = if (natGateway) {
//   name: 'ng-${name}'
//   location: deploymentParams.location
//   tags: tags
//   sku: {
//     name: 'Standard'
//   }
//   properties: {
//     idleTimeoutInMinutes: 4
//     publicIpAddresses: [
//       {
//         id: pip.id
//       }
//     ]
//   }
// }

// resource pip 'Microsoft.Network/publicIPAddresses@2021-03-01' = if (natGateway) {
//   name: 'pip-ng-${name}'
//   location: deploymentParams.location
//   tags: tags
//   sku: {
//     name: 'Standard'
//   }
//   properties: {
//     publicIPAllocationMethod: 'Static'
//   }
// }


output vnetId string = r_vnet.id
output vnetName string = r_vnet.name
output vnetSubnets array = r_vnet.properties.subnets
output tags object = tags

