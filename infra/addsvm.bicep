@description('Time Zone')
@allowed([
  'Central Europe Standard Time'
  'Pacific Standard Time'
  'W. Europe Standard Time'
])
param TimeZone string = 'Pacific Standard Time'

param _artifactsLocation string 

@description('Auto-generated token to access _artifactsLocation')
@secure()
param _artifactsLocationSasToken string

@description('The name of the Administrator of the new VM and Domain')
param adminUsername string

@description('The password for the Administrator account of the new VM and Domain')
@secure()
param adminPassword string

@description('Windows Server OS License Type')
@allowed([
  'None'
  'Windows_Server'
])
param WindowsServerLicenseType string = 'None'

@description('VNet1 Name')
@maxLength(10)
param NamingConvention string

@description('Sub DNS Domain Name Example:  sub1. must include a DOT AT END')
param SubDNSDomain string = ''

@description('NetBios Parent Domain Name')
@maxLength(15)
param NetBiosDomain string = 'mttdemodomain'

@description('NetBios Domain Name')
param InternalDomain string = 'mttdemodomain'

@description('Top-Level Domain Name')
@allowed([
  'com'
  'net'
  'org'
  'edu'
  'gov'
  'mil'
  'us'
  'tk'
  'ml'
  'local'
])
param InternalTLD string = 'com'

@description('VNet1 Prefix')
param vnet1ID string = '10.1'

@description('DNS Reverse Lookup Zone1 Prefix')
param ReverseLookup1 string = '1.10'

@description('Domain Controller1 OS Version')
@allowed([
  '2022-Datacenter'
  '2019-Datacenter'

])
param DC1OSVersion string = '2022-Datacenter'

@description('Domain Controller1 VMSize')
param DC1VMSize string = 'Standard_D2s_v3'

//@description('The location of resources, such as templates and DSC modules, that the template depends on')
//param _artifactsLocation string = ''

//@description('Auto-generated token to access _artifactsLocation. Leave it blank unless you need to provide your own value.')
//@secure()
//param _artifactsLocationSasToken string = ''

var vnet1Name = '${NamingConvention}-VNet1'
var vnet1Prefix = '${vnet1ID}.0.0/16'
var vnet1subnet1Name = '${NamingConvention}-VNet1-Subnet1'
var vnet1subnet1Prefix = '${vnet1ID}.1.0/24'
var vnet1subnet2Name = '${NamingConvention}-VNet1-Subnet2'
var vnet1subnet2Prefix = '${vnet1ID}.2.0/24'
var vnet1BastionsubnetPrefix = '${vnet1ID}.253.0/24'
var dc1name = '${NamingConvention}-dc-01'
var dc1IP = '${vnet1ID}.1.${dc1lastoctet}'
//var ReverseLookup1 = '1.${ReverseLookup1}'
var ForwardLookup1 = '${vnet1ID}.1'
var dc1lastoctet = '101'
var DCDataDisk1Name = 'NTDS'
var InternaldomainName = '${SubDNSDomain}${InternalDomain}.${InternalTLD}'

module VNet1 'linkedtemplates/vnet.bicep' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('ADDS_VM/.azure/linkedtemplates/vnet.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'VNet1'
  params: {
    vnetName: vnet1Name
    vnetprefix: vnet1Prefix
    subnet1Name: vnet1subnet1Name
    subnet1Prefix: vnet1subnet1Prefix
    subnet2Name: vnet1subnet2Name
    subnet2Prefix: vnet1subnet2Prefix
    BastionsubnetPrefix: vnet1BastionsubnetPrefix
    location: resourceGroup().location
  }
}

module BastionHost1 'linkedtemplates/bastionhost.bicep' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('ADDS_VM/.azure/linkedtemplates/bastionhost.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'BastionHost1'
  params: {
    publicIPAddressName: '${vnet1Name}-Bastion-pip'
    AllocationMethod: 'Static'
    vnetName: vnet1Name
    subnetName: 'AzureBastionSubnet'
    location: resourceGroup().location
  }
  dependsOn: [
    VNet1
  ]
}

module deployDC1VM 'linkedtemplates/1nic-2disk-vm.bicep' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('ADDS_VM/.azure/linkedtemplates/1nic-2disk-vm.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'deployDC1VM'
  params: {
    computerName: dc1name
    computerIP: dc1IP
    Publisher: 'MicrosoftWindowsServer'
    Offer: 'WindowsServer'
    OSVersion: DC1OSVersion
    licenseType: WindowsServerLicenseType
    DataDisk1Name: DCDataDisk1Name
    VMSize: DC1VMSize
    vnetName: vnet1Name
    subnetName: vnet1subnet1Name
    adminUsername: adminUsername
    adminPassword: adminPassword
    TimeZone: TimeZone
    location: resourceGroup().location
  }
  dependsOn: [
    VNet1
  ]
}

module promotedc1 'linkedtemplates/firstdc.bicep' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('ADDS_VM/.azure/linkedtemplates/firstdc.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'promotedc1'
  params: {
    computerName: dc1name
    TimeZone: TimeZone
    NetBiosDomain: NetBiosDomain
    domainName: InternaldomainName
    adminUsername: adminUsername
    adminPassword: adminPassword
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    location: resourceGroup().location
  }
  dependsOn: [
    deployDC1VM
  ]
}

module updatevnet1dns 'linkedtemplates/updatevnetdns.bicep' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('ADDS_VM/.azure/linkedtemplates/updatevnetdns.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'updatevnet1dns'
  params: {
    vnetName: vnet1Name
    vnetprefix: vnet1Prefix
    subnet1Name: vnet1subnet1Name
    subnet1Prefix: vnet1subnet1Prefix
    subnet2Name: vnet1subnet2Name
    subnet2Prefix: vnet1subnet2Prefix
    BastionsubnetPrefix: vnet1BastionsubnetPrefix
    DNSServerIP: [
      dc1IP
    ]
    location: resourceGroup().location
  }
  dependsOn: [
    promotedc1
  ]
}

module restartdc1 'linkedtemplates/restartvm.bicep' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('ADDS_VM/.azure/linkedtemplates/restartvm.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'restartdc1'
  params: {
    computerName: dc1name
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    location: resourceGroup().location
  }
  dependsOn: [
    updatevnet1dns
  ]
}

module configdns 'linkedtemplates/configdnsint.bicep' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('ADDS_VM/.azure/linkedtemplates/configdnsint.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'configdns'
  params: {
    computerName: dc1name
    NetBiosDomain: NetBiosDomain
    InternaldomainName: InternaldomainName
    ReverseLookup1: ReverseLookup1
    ForwardLookup1: ForwardLookup1
    dc1lastoctet: dc1lastoctet
    adminUsername: adminUsername
    adminPassword: adminPassword
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    location: resourceGroup().location
  }
  dependsOn: [
    restartdc1
  ]
}
