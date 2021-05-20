param sqlServerName string
param sqlDatabaseName string
param sqlServerAdminName string
@secure()
param sqlServerAdminPassword string
param logAnalyticsWorkspaceId string


resource sqlServer 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: sqlServerName
  location: resourceGroup().location
  properties: {
    administratorLogin: sqlServerAdminName
    administratorLoginPassword: sqlServerAdminPassword
  }

  resource db 'databases@2020-08-01-preview' = {
    name: sqlDatabaseName
    location: resourceGroup().location
    sku: {
      name: 'Basic'
    }
  }

  resource sqlFirewallRule 'firewallRules@2015-05-01-preview' = {
    name: 'allowInboundTraffic'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
}

resource dbDiagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  scope: sqlServer::db
  name: 'logAnalytics-${sqlDatabaseName}'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { 
        category: 'SQLInsights' 
        enabled: true 
      }
      {
        category: 'AutomaticTuning'
        enabled: true
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
      }
      {
        category: 'QueryStoreWaitStatistics'
        enabled: true
      }
      {
        category: 'Errors'
        enabled: true
      }
      {
        category: 'DatabaseWaitStatistics'
        enabled: true
      }
      {
        category: 'Timeouts'
        enabled: true
      }
      {
        category: 'Blocks'
        enabled: true
      }
      {
        category: 'Deadlocks'
        enabled: true
      }
    ]
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
  }
}

output sqlServerFQDN string = sqlServer.properties.fullyQualifiedDomainName
