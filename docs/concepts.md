# Template concepts

The goal of using this template is to make it easy to dive straight into implementing business logic without having to spend time on setting up an engineering system for your application. The template gives you a starting point, while providing the option to change and extend any of the pre-configured components to suit your needs.

The template make use of an opinionated pattern that Microsoft recommends to use for applications targeting the Azure Application Platform.

This document describes the concepts we have built into the template.

- [Template concepts](#template-concepts)
  - [Development Environment](#development-environment)
    - [Development Environment Host](#development-environment-host)
    - [IDE](#ide)
  - [The application](#the-application)
  - [Build and Deployment](#build-and-deployment)
    - [Install.sh script](#installsh-script)
    - [Resource definitions - Infrastructure-as-code](#resource-definitions---infrastructure-as-code)
    - [Resource naming](#resource-naming)
      - [Algorithm inputs](#algorithm-inputs)
      - [Resource group name](#resource-group-name)
      - [Other resource names](#other-resource-names)
      - [Limitations](#limitations)
  - [GitHub Action workflows](#github-action-workflows)
    - [The `build_release` workflow](#the-build_release-workflow)
  - [Cost of using the template](#cost-of-using-the-template)

## Development Environment

The template gets you up and running quickly by providing a pre-configured development environment.

This template supports the following development environment:
- VS Code using dev containers
   - This requires you to have VS Code and Docker Desktop installed. You can use macOS or Windows + WSL2.
- Codespaces using Microsoft Edge Browser
   - No requirements.
- Visual Studio 2019 on Windows
   - Requires .NET 3.1 SDK, Docker Desktop, Docker Compose, and [sqlcmd utility](https://docs.microsoft.com/sql/tools/sqlcmd-utility?view=sql-server-ver15).

### Development Environment Host

To run the app inside of a local development container, this template uses the [VS Code Remote - Containers extension](https://code.visualstudio.com/docs/remote/containers) and [Docker](https://docs.docker.com/) to build a self-contained development environment on your machine. The Remote - Containers extension leverages the [`devcontainer.json`](../.devcontainer/devcontainer.json) file to create a development container with the required settings and extensions installed. This method minimizes dev machine set up, but it requires Docker to build a container and a local instance of VS Code to connect to the development container.

The development container definition includes not only the required runtimes for the application and an instance of the database, but also the tools you will need installed on your development machine (e.g. CLIs). Check out the [`.devcontainer`](../.devcontainer/) folder to see how it is implemented.

You also have the option to run the template via [GitHub Codespaces](https://code.visualstudio.com/docs/remote/codespaces). Codespaces hosts the development container defined by [`devcontainer.json`](../.devcontainer/devcontainer.json), but in Azure instead of on your local dev machine.

To connect to Codespaces from VS Code locally, you need to install the [GitHub Codespaces extension](https://marketplace.visualstudio.com/items?itemName=GitHub.codespaces).

Using Codespaces also allows you to run this template entirely from a browser which means both VS Code and Docker are **not required** on your PC. 

As soon as the template is opened in a dev container (including in Codespaces), the `init.sh` or `init/.ps1` script located in the [scripts](../scripts/webapi/) folder is executed. This script generates secrets for your local environment and build the app dependencies and initialize a local instance of the database. This is what makes the template instantly runnable.

>**Important:** Modifying **any file** in the [`.devcontainer folder`](../.devcontainer/) requires you to open the Command Palette (`Ctrl + Shift + P`  or `CMD + Shift + P`) and run **Remote-Containers: Rebuild Container** or **Remote-Containers: Rebuild and Reopen in Container** depending on if you are in a dev container or not.

### IDE

Along with a definition of the host environment, the template also includes a configuration to build and run your app in VS Code or Visual studio 2019.

## The application

The application is comprised of a Web API implemented in .NET as well as an AzureSQL database.

## Build and Deployment

The template have a ready-to-run build and deployment workflow to quickly get your application up and running in the cloud.

### Install.sh script

The deployment workflow uses the [install.sh](../deploy/scripts/install.sh) script, which can also be run from your dev environment to validate deployments.

The script supports both local execution as well as execution in the pipeline. For local execution it makes it easy to test changes to the deployment flow or resources, without having to rebuild code and update an existing environment.

**Note** The script uses tags on the resource group `--resource-group-tag`, to identify if the resource group is "owned" by an automated deployment pipeline in a given repository.

In order to run the script from you development environment, ensure the following:
1. Have Azure CLI installed and be logged in to Azure from the cli using `az login`
1. Have selected the desired active subscription (`az account set`) and, if necessary, have selected desired cloud (`az cloud set`)

> Run "install.sh --help" to learn about all options supported by the script

[This diagram shows the flow in the script](assets/install_script.png).

### Resource definitions - Infrastructure-as-code

[Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/bicep-overview) is a domain-specific-language for authoring Azure Resource Manager (ARM) templates. Bicep files specify which Azure Resources are created for deployment.

All resource definitions are implemented in the [/deploy/infra](/deploy/infra/) folder, where the [main.bicep](/deploy/infra/main.bicep) file loads each individual resource as a module.

All resources are created and enabled with diagnostics and monitoring. You can use [Application Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview) to analyze your application's performance and [Log Analytics](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview) to analyze logs and metrics from all resources deployed.

### Resource naming

The install script and workflow relies on information from the [config.yaml](../deploy/config.yaml) file to determine name of resource group and resources. Any changes to the [config.yaml](../deploy/config.yaml) file, which will change the resource group and resources names, will result in the workflow creating new resources (e.g. databases). Renaming an existing deployment is not supported.

This following section describes the algorithm for choosing names of Azure resources created during the deployment.

The algorithm follows [Azure Cloud Adoption Framework naming convention](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming) with the exception that Azure region is not included in resource names, primarily to increase the chance that the generated names fall within maximum name length limits.

No resource naming logic is defined in Bicep files. All Bicep files take resource names as mandatory parameters.

#### Algorithm inputs

The inputs to the algorithm (data that determines the generated resource names) are:
1. Deployment environment definition
1. The name of the GitHub repository for the application. 
1. The Azure subscription used for deployment. 

The rest of the document uses an example repository named `webapi-dotnet` with the following [configuration](/deploy/config.yaml):

```yaml
AZURE_LOCATION: "northeurope"
RESOURCE_NAME_PREFIX: "dotnetwebapi"
ENVIRONMENT_TAG: "tst"
```

#### Resource group name

The resource group name will be named according to the following pattern:

    rg-{GitHub repository name}-{environment tag}

For example, with the environment defined above, the resulting resource group name will be `rg-webapi-dotnet-tst`.

#### Other resource names

Resources other than the resource group will be named according to the following pattern:

    {resource type code}-{resource name prefix}-{environment tag}-{uniquifying suffix}[-{multiple resource differentiator}]

The algorithm will use [Cloud Adoption Framework recommended resource type abbreviations](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations) if available. For example `sqldb` will be used for Azure SQL databases, `app` for web apps, `kv` for KeyVault, `st` for storage accounts and so on. |

`uniquifying suffix` is a 6-letter, all-lowercase suffix that is generated by hashing the fully-qualified resource group ID (which includes the Azure subscription ID). It is used to avoid naming conflicts between deployments to different environments.

If hyphens are not allowed in the resource name (e.g. for storage accounts), the elements of the name will not be separated.

Examples:

- a KeyVault: `kv-webapi-tst-juebbq` 
- an AppService website: `app-webapi-tst-juebbq` 
- storage account for database files, using `db` as multiple resource differentiator: `stwebapitstjuebbqdb` 
- second storage account in the deployment (multiple resource differentiator not specified):  `stwebapitstjuebbq002`

To ensure that each resource name does not exceed the maximum length (specific to resource type) names will be shortened (truncated) by shortening or removing altogether the environment tag and resource name prefix elements (in that order of priority).

#### Limitations

Support for deploying to multiple resource groups is out of scope for the template.

The resource naming algorithm does not guarantee that multiple templates deployed in the same subscription will not conflict on names. In particular, if "team" subscriptions are used, there is a probability that there will be a conflict related to the resource group name. Make sure you are using different `RESOURCE_NAME_PREFIX` and / or `ENVIRONMENT_TAG` to prevent this. Naming conflicts for other resources are unlikely because they get a differentiating suffix based on the full resource group ID.

## GitHub Action workflows

[GitHub workflows](https://docs.github.com/actions/learn-github-actions/introduction-to-github-actions) enable you to run automated tasks when you commit changes to your repo. Workflows invoke GitHub Actions which are simply sequential tasks to complete within the workflow. Workflows can be trigger-based (such as committing code) or manual.

### The `build_release` workflow

This workflow is responsible for:

- Building and testing the application code as binaries or containers.
- Validating the Bicep files and compiling them to ARM templates.
- Evaluating the [`deploy/config.yaml`](../deploy/config.yaml) file for the configuration to use.
- Initiating installation.

First, the application code is built and tested. Then, the compiled output is uploaded as an artifact to either the repository or a container registry, depending on the implementation.

The Bicep files are then trans-piled to ARM and are uploaded as artifacts.

Finally, the Azure resources are created or updated and the latest application code deployed.

This workflow is initiated:

- On any change to files in the [`services folder`](/services)
- On any change to files in the [`deploy folder`](/deploy)
- On any changes to the workflow itself

> **Note:** Currently, the workflow does not have a way to delete deployments. You will have to manually delete the resource group representing a deployment. You can do this by invoking the `install.sh` script with the `--uninstall` option.

> **Note:** This template creates a KeyVault, which will need to be purged after being soft deleted. For more information look [here](https://docs.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview).

## Cost of using the template

This template creates the following resources once deployed to Azure:
- Azure Monitor
  - Log Analytics Workspace receiving all diagnostics logs and metrics from all resources
  - Application Insights diagnostics from the WebAPI
- Azure SQL
  - Single Database Basic with DTU pricing model
- Azure KeyVault
  - Standard
- Azure App Service
  - Basic (B1) running Windows

Please use the [Azure pricing calculator](https://azure.microsoft.com/pricing/calculator) to estimate the cost of running theses services.