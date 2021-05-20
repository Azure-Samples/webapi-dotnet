param logAnalyticsWorkspaceName string
param applicationInsightsName string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWorkspaceName
  location: resourceGroup().location
  properties: {
  }
}

resource ai 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: applicationInsightsName
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

output appInsightsInstrumentationKey string = ai.properties.InstrumentationKey
output logAnalyticsWorkspaceId string = logAnalytics.id
