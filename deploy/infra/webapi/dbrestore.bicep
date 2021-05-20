param sqlServerName string
param sqlDatabaseName string
param dbInitializationFileUrl string

@secure()
param sqlServerAdminPassword string 
@secure()
param dbInitializationFileAccessKey string

var sqlServerAdminName = 'azure_dba'

resource dbrestore 'Microsoft.Sql/servers/databases/extensions@2014-04-01' = {
  name: '${sqlServerName}/${sqlDatabaseName}/webapidb-restore'
  properties: {
    administratorLogin: sqlServerAdminName
    administratorLoginPassword: sqlServerAdminPassword
    storageKey: dbInitializationFileAccessKey
    storageKeyType: 'StorageAccessKey'
    storageUri: dbInitializationFileUrl
    operationMode: 'Import'
  }
}
