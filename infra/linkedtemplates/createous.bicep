@description('Computer Name')
param computerName string

@description('Base Domain Distiguished Name')
param BaseDN string

@description('The location of resources, such as templates and DSC modules, that the template depends on')
param _artifactsLocation string = 'https://attdemodeploystoacc.blob.core.windows.net/deployartifacts/deploytemplateartifacts'

@description('Auto-generated token to access _artifactsLocation')
@secure()
param _artifactsLocationSasToken string

@description('Region of Resources')
param location string

var ModulesURL = uri(_artifactsLocation, 'ADDS_VM/.azure/DSC/CREATEOUS.zip${_artifactsLocationSasToken}')
var ConfigurationFunction = 'CREATEOUS.ps1\\CREATEOUS'

resource computerName_Microsoft_Powershell_DSC 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  name: '${computerName}/Microsoft.Powershell.DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: '${_artifactsLocation}DSC/CREATEOUS.zip?raw=true'
      ConfigurationFunction: ConfigurationFunction
      Properties: {
        BaseDN: BaseDN
      }
    }
  }
}
