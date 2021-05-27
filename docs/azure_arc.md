# Deploying to Azure Arc

This template supports deployment to Azure Arc. The following document lists the requirements to setup Azure Arc to support the template, as well as how you deploy the application to an Arc-enable Kubernetes Cluster.

- [Deploying to Azure Arc](#deploying-to-azure-arc)
  - [Prerequisites](#prerequisites)
  - [Regions and resource group support](#regions-and-resource-group-support)
    - [Azure Arc enabled App Service](#azure-arc-enabled-app-service)

## Prerequisites

In order to deploy this template to Azure Arc, you need to have the Arc-enabled Kubernetes Cluster created. This template assumes this has already been done. To learn more about configuring an Arc environment for App Service, please see the following: https://docs.microsoft.com/en-us/azure/azure-arc/

## Regions and resource group support

The following is a list of regions supported:

| Resource | Regions | Other requirements |
| --- | --- | ---- |
| Kubernetes cluster | anywhere | none |
| Kubernetes - Azure Arc | East US | none |
| Log Analytics | anywhere - preferably close to the Kubernetes clusters | none |
| Custom Location | East US | none |
| App Service Kubernetes Environment | East US or West Europe | none |
| App Plan | East US or West Europe | none |
| Web Site | East US or West Europe | Has to be in same resource group as the App Plan |


### Azure Arc enabled App Service

Following these guidelines will deploy the webapi to an ARC-enabled Kubernetes cluster.

For local development the following is needed:

1. Get updated bicep tools
   1. CLI:
      1. Download CLI (7aca810747) https://github.com/Azure/bicep/suites/2816103963/artifacts/62679913
         Using nightly.link because GitHub requires authentication to download artifacts --> https://github.com/actions/upload-artifact/issues/51
         `curl -L https://nightly.link/Azure/bicep/actions/artifacts/62679913.zip --output bicep.zip`
      1. Check integrity - sha256sum expected: 6179da0ac8e1bebea8f9101cb9f3a40ad1bc06b04355698043d5c83be9f28f15
         `echo 6179da0ac8e1bebea8f9101cb9f3a40ad1bc06b04355698043d5c83be9f28f15 bicep.zip | sha256sum --check`
      1. Unzip to path and change permissions
         `sudo unzip bicep.zip bicep -d /usr/local/bin && sudo chmod +x /usr/local/bin/bicep`
      1. Check version --> Bicep CLI version 0.3.602 (7aca810747)
         `bicep -v`
   1. TBD - VS Code extension and language server

To deploy from local environment do the following:

1. ARM for Plan and app in the template repo
   1. Build bicep
      `bicep build ./deploy/infra/main.bicep`
   1. Run install
      ```
      ./deploy/scripts/install.sh \
         --resource-name-prefix <rg name> --environment-tag <name tag> \
         --resource-group-tag <RG tag> \
         --location <rg ans Azure resource location> \
         --kube-environment-id <kubeEnv-id> \
         --custom-location-id <customLocation-id> \
         --arc-location <local of kubeenvironment resource>
      ```

To deploy using the GitHub Actions Workflow, the following is needed in the [config.yaml](../deploy/config.yaml) file:

```
AZURE_LOCATION: "northeurope"       #Location of Azure hosted resources, e.g. Azure Monitor
RESOURCE_NAME_PREFIX: "nodewebapi"  #Resource name prefix
ENVIRONMENT_TAG: "test"             #Resource tag
WEBAPI_NODE_ENV: "development"      #nodeEnv parameter
KUBE_ENVIRONMENT_ID: ""             #kubeEnvironmentId to host the webapi on Arc
CUSTOM_LOCATION_ID: ""              #customLocationId for the kubeEnvironment
ARC_LOCATION: ""                    #Location of the Arc resources - e.g. Web App
```
