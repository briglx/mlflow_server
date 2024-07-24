targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@minLength(1)
@maxLength(64)
@description('Application name')
param applicationName string
param acrName string = ''
param acrSku string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, applicationName, environmentName, location))
var tags = { 'app-name': applicationName, 'env-name': environmentName }

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${applicationName}_${environmentName}_${location}'
  location: location
  tags: tags
}

/////////// Common ///////////

// Azure Container Registry
module containerRegistry './core/host/containerregistry.bicep' = {
  name: 'containerRegistry'
  scope: rg
  params: {
    name: !empty(acrName) ? acrName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
    acrSku: !empty(acrSku) ? acrSku : 'Basic'
  }
}

output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_LOCATION string = location
output RESOURCE_TOKEN string = resourceToken
output AZURE_RESOURCE_GROUP_NAME string = rg.name
