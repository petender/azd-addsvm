@description('The name of the Virtual Network to Create')
param vnetName string

@description('The address range of the new VNET in CIDR format')
param vnetprefix string

@description('The name of the subnet1 created in the new VNET')
param subnet1Name string

@description('The address range of the subnet1 created in the new VNET')
param subnet1Prefix string

@description('The name of the subnet2 created in the new VNET')
param subnet2Name string

@description('The address range of the subnet2 created in the new VNET')
param subnet2Prefix string

@description('The address range of the subnet created in the new VNET')
param BastionsubnetPrefix string

@description('The DNS address(es) of the DNS Server(s) used by the VNET')
param DNSServerIP array

@description('Location for all resources.')
param location string

resource vnet 'Microsoft.Network/virtualNetworks@2020-04-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetprefix
      ]
    }
    dhcpOptions: {
      dnsServers: DNSServerIP
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: BastionsubnetPrefix
        }
      }
    ]
  }
}
