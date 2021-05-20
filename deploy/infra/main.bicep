param keyVaultName string
param sqlServerName string
@secure()
param sqlServerAdminPassword string
param applicationInsightsName string
param logAnalyticsWorkspaceName string
param webAppHostingPlanName string
param webAppName string

var sqlServerAdminName = 'azure_dba'
var sqlDatabaseName = 'webapidb'

module monitoring './webapi/monitoring.bicep' = {
  name: 'monitoring_deploy'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
  }
}
module db './webapi/db.bicep' = {
  name: 'db_deploy'
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    sqlServerAdminName: sqlServerAdminName
    sqlServerAdminPassword: sqlServerAdminPassword
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

module webapp './webapi/webapp.bicep' = {
  name: 'webapp_deploy'
  params: {
    webAppHostingPlanName: webAppHostingPlanName
    webAppName: webAppName
    appInsightsInstrumentationKey: monitoring.outputs.appInsightsInstrumentationKey
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

module secrets './webapi/secrets.bicep' = {
  name: 'secrets_deploy'
  params: {
    keyVaultName: keyVaultName
    webAppPrincipalId: webapp.outputs.webAppPrincipalId
    sqlServerFQDN: db.outputs.sqlServerFQDN
    sqlDatabaseName: sqlDatabaseName
    sqlServerAdminName: sqlServerAdminName
    sqlServerAdminPassword: sqlServerAdminPassword
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}
output webAppName string = webAppName
output sqlDatabaseName string = sqlDatabaseName
