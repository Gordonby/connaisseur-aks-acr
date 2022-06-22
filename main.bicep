param nameseed string = 'cimagev'
param location string =  resourceGroup().location

//---------Kubernetes Construction---------
module aksconst 'aks-construction/bicep/main.bicep' = {
  name: 'aksconstruction'
  params: {
    location : location
    resourceName: nameseed
    enable_aad: true
    enableAzureRBAC : true
    registries_sku: 'Premium'
    enableACRTrustPolicy: true
    omsagent: true
    retentionInDays: 30
    agentCount: 2
    JustUseSystemPool: true
  }
}
output AcrResourceId string = resourceId('Microsoft.ContainerRegistry/registries',aksconst.outputs.containerRegistryName)
output AksName string = aksconst.outputs.aksClusterName

var containerImages = [
  'securesystemsengineering/connaisseur:v2.6.0'
  'mcr.microsoft.com/azuredocs/azure-vote-front:v2'
]
module acrImport 'br/public:deployment-scripts/import-acr:2.0.1' = {
  name: 'Import-Images'
  params: {
    acrName: aksconst.outputs.containerRegistryName
    location: location
    images: containerImages
  }
}

