// Azure Bicep template for BB TPP API Simulator
// Provisions: App Service Plan, App Service, Key Vault

@description('Application name (used as prefix for resources)')
param appName string = 'bb-tpp-api-sim'

@description('Environment (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Azure region for resources')
param location string = resourceGroup().location

@description('App Service Plan SKU')
@allowed([
  'F1'  // Free
  'B1'  // Basic
  'S1'  // Standard
  'P1v2' // Premium
])
param appServicePlanSku string = 'B1'

@description('Node.js version')
param nodeVersion string = '18-lts'

@description('Your public IP for Key Vault firewall (optional)')
param allowedIpAddress string = ''

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var appServicePlanName = '${appName}-plan-${environment}'
var appServiceName = '${appName}-${environment}-${uniqueSuffix}'
var keyVaultName = '${appName}-kv-${uniqueSuffix}'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// App Service
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|${nodeVersion}'
      alwaysOn: appServicePlanSku != 'F1' // Always On not available on Free tier
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'PORT'
          value: '8080'
        }
        {
          name: 'PRIORA_URL'
          value: 'priora.saltedge.com'
        }
        {
          name: 'PROTOCOL'
          value: 'https'
        }
        {
          name: 'OB_PROVIDER_CODE'
          value: 'backbase_dev_uk'
        }
        {
          name: 'REDIRECT_URI'
          value: 'https://${appServiceName}.azurewebsites.net/callback'
        }
        // Key Vault references will be added by deployment script
      ]
    }
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: false
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: appService.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    networkAcls: allowedIpAddress != '' ? {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: [
        {
          value: allowedIpAddress
        }
      ]
    } : {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Outputs
output appServiceName string = appService.name
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output appServicePrincipalId string = appService.identity.principalId
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output resourceGroupName string = resourceGroup().name

