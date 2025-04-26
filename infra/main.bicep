targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param adminusername string
param adminpassword string

@description('VNet1 Name')
@maxLength(10)
param NamingConvention string = take(environmentName, 10)

param _artifactsLocation string = 'https://github.com/petender/azd-addsvm/blob/main/infra/'

@description('Auto-generated token to access _artifactsLocation')
@secure()
param _artifactsLocationSasToken string = ''

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

// This deploys the Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// add a module for a virtual machine which will be used as a domain controller
module addsvm 'addsvm.bicep' = {
  name: 'vm-${take(environmentName, 15)}'
  scope: rg
  params: {
    TimeZone: 'Pacific Standard Time'
    adminUsername: adminusername //'adminuser'
    adminPassword: adminpassword //'P@ssw0rd!'
    WindowsServerLicenseType: 'None'
    NamingConvention: NamingConvention
    SubDNSDomain: 'sub1.'
    NetBiosDomain: 'mttdemodomain'
    InternalDomain: 'mttdemodomain'
    InternalTLD: 'com'
    vnet1ID: '10.1'
    ReverseLookup1: '1.10'
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    
  }
}

// Add outputs from the deployment here, if needed.
//
// This allows the outputs to be referenced by other bicep deployments in the deployment pipeline,
// or by the local machine as a way to reference created resources in Azure for local development.
// Secrets should not be added here.
//
// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
