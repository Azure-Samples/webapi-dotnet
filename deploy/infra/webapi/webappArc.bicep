param webAppHostingPlanName string
param webAppName string
param appInsightsInstrumentationKey string
param keyVaultName string
param logAnalyticsWorkspaceId string
param kubeEnvironmentId string
param customLocationId string
param location string
param sqlServerFQDN string
param sqlDatabaseName string
param sqlServerAdminName string
@secure()
param sqlServerAdminPassword string

resource webAppHostingPlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: webAppHostingPlanName
  location: location
  kind: 'linux,kubernetes'
  sku: {
    name: 'K1'
    tier: 'Kubernetes'
    capacity: 1
  }
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    reserved: true
    perSiteScaling: true
    isXenon: false
    kubeEnvironmentProfile: {
      id: kubeEnvironmentId
    }
  }
}

resource webApp 'Microsoft.Web/sites@2020-12-01' = {
  name: webAppName
  location: location
  kind: 'linux,kubernetes,app'
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    serverFarmId: webAppHostingPlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|3.1'
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPINSIGHTS_PROFILERFEATURE_VERSION'
          value: '1.0.0'
        }
        {
          name: 'APPINSIGHTS_SNAPSHOTFEATURE_VERSION'
          value: '1.0.0'
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }        
        {
          name: 'DiagnosticServices_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'InstrumentationEngine_EXTENSION_VERSION'
          value: 'disabled'
        }
        {
          name: 'SnapshotDebugger_EXTENSION_VERSION'
          value: 'disabled'
        }
        {
          name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS'
          value: '7'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '6.9.1'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_BaseExtensions'
          value: 'disabled'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_PreemptSdk'
          value: '1'
        }
        {
          name: 'SQLCONNSTRING'
          value: 'Data Source=tcp:${sqlServerFQDN},1433;Database=${sqlDatabaseName};User ID=${sqlServerAdminName};Persist Security Info=True;Password=${sqlServerAdminPassword}'
        }
      ]
    }
  }
}

resource diagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  scope: webApp
  name: 'logAnalytics-${webAppName}'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceFileAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceAntivirusScanAuditLogs'
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
