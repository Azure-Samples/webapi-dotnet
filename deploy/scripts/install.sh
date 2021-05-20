#!/usr/bin/env bash

# Pipelines are considered failed if any of the constituent commands fail
set -o pipefail

usage()
{
    cat <<END
install --resource-name-prefix <resource name prefix> --environment-tag <environment tag> --location <Azure region> --resource-group-tag <resource group tag> [--overwrite] [--resource-group-name <resource group name>] [--no-build] [--no-deploy] [--uninstall]

Deploys the dotnet-webapi sample to specified Azure region by performing the following steps:
  1. Build the application and zip the binaries for deployment.
  2. Create resource gropup for the application.
  3. Create Azure assets: the secret key vault, storage account
     App Service instance, and SQL server instance.
  4. Initialize and seed the database.
  5. Deploy the web site to the App Service instance.

Options:
  --overwrite
    Will delete the existing resource group if it exists.
  --resource-group-name <resource group name>
    Use specified name for the resource group instead of default one.
  --no-build
    Do not perform application build, just deploy the app.
  --no-deploy
    Just do the application build, do not deploy (or uninstall) the app.
  --uninstall
    Uninstall the application (delete its resource group and purge its keyvault).

Example invocation: install --resource-name-prefix webapi --environment-tag dev --location westus2 --resource-group-tag 20210506a

Assumptions: 
  1. The environment has Docker, Azure CLI, and jq installed.
  2. The user is logged in into Azure via Azure CLI, 
     and the desired Azure subscription is set.

Names of Azure resources often need to be globally unique. 
Use <resource name prefix> parameter to ensure that.
To avoid name validation issues use only lowercase letters and numbers
for resource name prefix and environment tag.

The resource group name and tag has to both match for existing resource groups.
This is to ensure you're not unintentionally overwriting an existing resource group.
If the resource group name and tag matches, the existing resource group will be updated.
Use the --overwrite option to have the script delete an existing resource group,
and create a new one using the same name.
END
}

# Generates random password that meets SQL Server password complexity criteria
get_sql_pwd() {
    declare -a lcase=() ucase=() numbers=()
    for i in {a..z}; do
        lcase[$RANDOM]=$i
    done
    for i in {A..Z}; do
        ucase[$RANDOM]=$i
    done
    for i in {0..9}; do
        numbers[$RANDOM]=$i
    done

    declare output_chars="${lcase[*]::5}${ucase[*]::5}${numbers[*]::4}"
    randval=${output_chars//[[:space:]]/}
    randval=$(echo "$randval" | fold -w1 | shuf | tr -d '\n')
    echo ${randval}
}

# Check if we have Azure accounts
accounts=$(az account list --all --only-show-errors | jq length)
if [[ $accounts == 0 ]]; then
    echo "Please sign in to Azure, and re-run the script."
    exit 1
fi

no_build=""
no_deploy=""
overwrite=''
resource_name_prefix=''
environment_tag=''
region=''
rg_tag=''
resource_group_name=''
uninstall=''

while [[ $# -gt 0 ]]; do
    case "$1" in
        --resource-name-prefix )
            resource_name_prefix="$2"; shift 2 ;;
        --environment-tag )
            environment_tag="$2"; shift 2 ;;
        --location )
            region="$2"; shift 2 ;;
        --resource-group-tag )
            rg_tag="$2"; shift 2 ;;
        --overwrite )
            overwrite='yes'; shift ;;
        --resource-group-name )
            resource_group_name="$2"; shift 2 ;;
        --no-build )
            no_build='yes'; shift ;;
        --no-deploy )
            no_deploy='yes'; shift ;;
        --uninstall )
            uninstall='yes'; shift ;;
        -h | --help )
            usage; exit 2 ;;
        *)
            echo "Unknown option '${1}'"; echo ""; usage; exit 3 ;;
    esac
done

# Validate the required script arguments are available
if [[ ! $no_deploy ]]; then
    if [[ ((! $resource_name_prefix) || (! $environment_tag)) || (! $region) || (! $rg_tag) ]]; then
        usage
        exit 4
    fi
fi

declare -r script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
declare -r root_dir="${script_dir}/../.."
declare -r vp_cli_image='ghtools.azurecr.io/vp-cli:0.1.1-alpha'

if [[ (! $no_build) ]]; then 
    echo "Building the application..."
    dotnet publish --output "${root_dir}/output/webapi" "${root_dir}/services/webapi/src/webapi.csproj" && \
        pushd "${root_dir}/output/webapi" && \
        zip -r ../webapi.zip . && \
        mv -f ../webapi.zip . && \
        popd
    if [[ $? -ne 0 ]]; then
        echo "There was an error during application build"
        exit 201
    fi
fi

if [[ $no_deploy ]]; then
    exit 0
fi

if [[ ! $resource_group_name ]]; then
    if [[ $GITHUB_REPOSITORY ]]; then
        # GITHUB_REPOSITORY includes owner name ('owner/repository'); we only want to use the repository name
        resource_group_name="rg-${GITHUB_REPOSITORY##*/}-${environment_tag}"
    else
        resource_group_name="rg-${resource_name_prefix}-${environment_tag}"
    fi
fi

resource_group=$(az group show --resource-group "$resource_group_name" 2>/dev/null)
resource_group_id=''
tag=''
if [[ $resource_group ]]; then
    resource_group_id=$(echo $resource_group | jq -r '.id')
    tag=$(echo $resource_group | jq -r '.tags.repo')
fi

if [[ $tag && ($tag != $rg_tag) && (! $overwrite) ]]; then
    echo "Resource group '${resource_group_name}' already exists, but has a different 'repo' tag: '${tag}' vs '${rg_tag}'. Use a different <resource name prefix> or the --overwrite option."
    exit 5
fi

if [[ ($resource_group && $overwrite) || $uninstall ]]; then
    echo "Deleting resource group '${resource_group_name}'..."
    az group delete --resource-group "$resource_group_name" --yes
    if [[ $? -ne 0 ]]; then
        echo "Resource group '${resource_group_name}' could not be deleted"
        exit 101
    fi

    keyvault_name=$(docker run -i --rm $vp_cli_image ./vp create-resource-name \
        --name-prefix $resource_name_prefix \
        --environment-tag $environment_tag \
        --unique-suffix-source $resource_group_id \
        --resource-type 'Microsoft.KeyVault/vaults')
    if [[ $? -ne 0 ]]; then
        echo "The name of the key vault to purge could not be determined"
        exit 102
    fi
    az keyvault purge --name "$keyvault_name"
    # Proceed even if key vault purge fails--it might not have been there in the first place.

    resource_group=''

    if [[ $uninstall ]]; then
        echo "Application uninstalled"
        exit 0
    fi
fi

if [[ ! $resource_group ]]; then
    echo "Creating resource group '${resource_group_name}'..."
    resource_group_id=$(az group create --resource-group "$resource_group_name" --location "$region" --tag "repo=$rg_tag" | jq -r '.id')
    if [[ $? -ne 0 ]]; then
        echo "Resource group '${resource_group_name}' could not be created"
        exit 6
    fi
fi

read -r -d '' request_common <<END
"type": "create-resource-name",
"namePrefix": "${resource_name_prefix}",
"environmentTag": "${environment_tag}",
"uniqueSuffixSource": "${resource_group_id}"
END
read -r -d '' batch_request <<END
{ "operations": [
    { ${request_common}, "resourceType": "Microsoft.Web/serverfarms" },
    { ${request_common}, "resourceType": "Microsoft.Web/sites" },
    { ${request_common}, "resourceType": "Microsoft.OperationalInsights/workspaces" },
    { ${request_common}, "resourceType": "Microsoft.Insights/components" },
    { ${request_common}, "resourceType": "Microsoft.KeyVault/vaults" },
    { ${request_common}, "resourceType": "Microsoft.Sql/servers" },
    { ${request_common}, "resourceType": "Microsoft.Storage/storageAccounts" },
    { ${request_common}, "resourceType": "Microsoft.Storage/storageAccounts/blobServices/containers" }
]}
END
batch_output=$(echo $batch_request | docker run -i --rm $vp_cli_image ./vp batch)
if [[ $? -ne 0 ]]; then
    echo "Could not compute names for Azure resources"
    exit 7
fi
readarray -t resource_names <<< "$batch_output"
web_app_hosting_plan_name=${resource_names[0]}
web_app_name=${resource_names[1]}
log_analytics_workspace_name=${resource_names[2]}
application_insights_name=${resource_names[3]}
keyvault_name=${resource_names[4]}
sql_server_name=${resource_names[5]}
storage_account_name=${resource_names[6]}
storage_container_name=${resource_names[7]}

echo "Creating storage account..."
az storage account create \
    --name "$storage_account_name" \
    --resource-group "$resource_group_name" \
    --location "$region" \
    --sku Standard_LRS
if [[ $? -ne 0 ]]; then
    echo "Storage account could not be created"
    exit 8
fi

echo "Retrieving storage account key..."
storage_account_key=$(az storage account keys list --account-name "$storage_account_name" --resource-group "$resource_group_name" | jq --raw-output '.[0].value')
if [[ $? -ne 0 ]]; then
    echo "Storage account key could not be retrieved"
    exit 9
fi

echo "Creating storage container for database intialization file..."
az storage container create \
    --name "$storage_container_name" \
    --account-key "$storage_account_key" \
    --account-name "$storage_account_name"
if [[ $? -ne 0 ]]; then
    echo "Storage container could not be created"
    exit 10
fi

echo "Uploading database initialization file..."
az storage blob upload \
    --container-name "$storage_container_name" \
    --file "${root_dir}/deploy/infra/webapi/webapidb.bacpac" \
    --account-key "$storage_account_key" \
    --account-name "$storage_account_name" \
    --name webapidb.bacpac 
if [[ $? -ne 0 ]]; then
    echo "Database initialization file could not be uploaded"
    exit 11
fi

deployment_name="deploy-${resource_name_prefix}-${environment_tag}"
db_deployment_name="db-deploy-${resource_name_prefix}-${environment_tag}"

echo "Create Azure assets..."
az bicep install
sql_password=$(get_sql_pwd)
deployment_result=$(az deployment group create \
    --resource-group "$resource_group_name" \
    --name "$deployment_name" \
    --template-file "${root_dir}/deploy/infra/main.bicep" \
    --parameters \
        keyVaultName=${keyvault_name} \
        sqlServerName=${sql_server_name} \
        sqlServerAdminPassword=${sql_password} \
        applicationInsightsName=${application_insights_name} \
        logAnalyticsWorkspaceName=${log_analytics_workspace_name} \
        webAppName=${web_app_name} \
        webAppHostingPlanName=${web_app_hosting_plan_name})
if [[ $? -ne 0 ]]; then
    echo "App Service and SQL Server deployment failed"
    exit 12
fi

echo "Azure assets created:"
echo $deployment_result

web_app_name=$(echo "$deployment_result" | jq -r '.properties.outputs.webAppName.value')
sql_database_name=$(echo "$deployment_result" | jq -r '.properties.outputs.sqlDatabaseName.value')

echo "Initializing the database..."
storage_account_endpoint="$(az storage account show --name ${storage_account_name} | jq -r '.primaryEndpoints.blob')"
db_initialization_file_url="${storage_account_endpoint}${storage_container_name}/webapidb.bacpac"
az deployment group create \
    --resource-group "$resource_group_name" \
    --name "$db_deployment_name" \
    --template-file "${root_dir}/deploy/infra/webapi/dbrestore.bicep" \
    --parameters \
        sqlServerName=${sql_server_name} \
        sqlDatabaseName=${sql_database_name} \
        sqlServerAdminPassword=${sql_password} \
        dbInitializationFileUrl=${db_initialization_file_url} \
        dbInitializationFileAccessKey=${storage_account_key}
# If we redeploy and the database exists, the above command might fail, but that is OK
# Eventually we will use a more robust database migration solution and handle errors better

echo "Deploying the website..."
az webapp deployment source config-zip \
    --name "$web_app_name" \
    --resource-group "$resource_group_name" \
    --src "${root_dir}/output/webapi/webapi.zip"
if [[ $? -ne 0 ]]; then
    echo "Website deployment failed"
    exit 13
fi

host_name=$(az webapp show --name "$web_app_name" --resource-group "$resource_group_name" | jq -r '.defaultHostName')
echo "Application deployed, the URL is https://${host_name}"
