param keyVaultName string
param webAppPrincipalId string
param sqlServerFQDN string
param sqlDatabaseName string
param sqlServerAdminName string
@secure()
param sqlServerAdminPassword string
param logAnalyticsWorkspaceId string


resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: resourceGroup().location
  properties: {
    enableSoftDelete: true
    tenantId: subscription().tenantId
    sku:{
      name: 'standard'
      family: 'A'
    }
    accessPolicies:[
      {
        tenantId: subscription().tenantId
        objectId: webAppPrincipalId
        permissions: {
          secrets: [ 
            'get' 
            'list' 
          ]
        }
      }
    ]
  }

  resource sqlServerConnectionString 'secrets@2019-09-01' = {
    name: 'SQLCONNSTRING'
    properties: {
      value: 'Data Source=tcp:${sqlServerFQDN},1433;Database=${sqlDatabaseName};User ID=${sqlServerAdminName};Persist Security Info=True;Password=${sqlServerAdminPassword}'
    }
  }
}

resource diagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  scope: keyVault
  name: 'logAnalytics-${keyVaultName}'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
