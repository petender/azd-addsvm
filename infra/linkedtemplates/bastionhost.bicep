@description('Public IP Address Name')
param publicIPAddressName string

@description('Public IP Allocation Method')
param AllocationMethod string

@description('Existing virtual Network Name')
param vnetName string

@description('Existing Subnet Name')
param subnetName string

@description('Region of Resources')
param location string

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2019-04-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: AllocationMethod
  }
}

resource vnet 'Microsoft.Network/bastionHosts@2020-04-01' = {
  name: vnetName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
  }
}
