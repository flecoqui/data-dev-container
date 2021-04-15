# Using Visual Studio Code with Data Science dev containers

# Table of Contents
- [Introduction](#introduction)
- [Using Visual Studio Code with dev containers](#using-visual-studio-code-with-dev-containers)
- [Azure DevOps Pipeline to deploy the dev container infrastructure](#azure-devops-pipeline-to-deploy-the-dev-container-infrastructure)
- [Azure DevOps Pipeline to build, test and push the dev container images](#azure-devOps-pipeline-to-build-test-and-push-the-dev-container-images)
- [Next steps](#next-steps)

## Introduction
This repository contains resources to create and use multiple Data Science dev containers with Visual Studio Code.
You'll see how to:
  - automate the generation of Data Science dev containers
  - test the Data Science dev containers in an Azure DevOps pipeline
  - store the Data Science dev containers images in Azure Container Registry 
  - deploy the cloud infrastructure used to stored the container images with an Azure DevOps pipeline.

This multiple data science dev containers approach has been used during a Data Science project which is described here https://aka.ms/hat-sharing.


With Visual Studio Code Remote Containers, the advantages are massive: 
- It is very easy to repeatedly provision the same coding environment in seconds.
- The coding environment itself can easily be adjusted and configured. This environment can be version controlled alongside the rest of the project.
- Whenever changes are made to the development environment, a developer can rebuild the container to have the newest changes and settings applied.
- It removes any versioning issues that can easily arise from installing items on different machines at different times.

For the project in this repository, a dev container has been created to provide several conda environements:
- localspark
- databricks connect
- JupyperLab 

As this dev container image size is around 6 GB, it could take time to build this dev container image on a low CPU machine or on a low memory machine.

Now for the project in this repository, it's possible to use different flavors of the dev container which require less memory:

|Type of dev container | Description |
|---------------------|-------------|
|Base | Base conda environment |
|localspark | Local Spark environment |
|db-connect | Databricks Connect environment |
|JupyterLab | JupyterLab environment |
|All | Local Spark, Databricks Connect and JupyterLab environment |

Moreover, in order to decrease the time to build the dev container image, the dev container images are prebuilt and available in an Azure Container Registry repository. If the bandwidth of your Internet connection is over 100 Mb/s, it will be faster to build your local dev container image using the prebuilt images. Visual Studio Code will directly download the prebuilt images which have already been tested.  

Below the list of prebuilt images:

|Type of dev container | Description |
|---------------------|-------------|
|Prebuilt Base | Base conda environment |
|Prebuilt localspark | Local Spark environment |
|Prebuilt db-connect | Databricks Connect environment |
|Prebuilt JupyterLab | JupyterLab environment |
|Prebuilt All | Local Spark, Databricks Connect and JupyterLab environment |

   ![](./docs/img/README.md/architecture.png)

This guide describes:
- how to create and use a pipeline to deploy the dev container Azure infrastructure (Azure Container Registry)
- how to create and use a pipeline to build and push the dev container images to Azure Container Registry
- how to use the dev container images with Visual Studio Code 

## Using Visual Studio Code with dev containers

### **Installing the pre-requisites**
Before you start to clone the repository on your machine, make sure your computer meets the following requirements:
- Operating System
  - [Windows 10 with WSL2](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
  - Linux
  - macOS
- Docker
  - [Docker Desktop for Mac](https://hub.docker.com/editions/community/docker-ce-desktop-mac)
  - [Docker Desktop for Windows 10](https://hub.docker.com/editions/community/docker-ce-desktop-windows)
- [Visual Studio Code](https://code.visualstudio.com/)
  - [VSCode Remote - Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
  - As the new devcontainer implementation requires you can also run Visual Studio Code from the terminal (Linux, MacOS) or from the Command Shell (Windows) by typing 'code', don't forget those configuration steps on MacOS:
    - Launch VS Code.
    - Open the Command Palette (Ctrl+Shift+P) and type 'shell command' to find the "Shell Command: Install 'code' command in PATH" command.  
    ![](./docs/img/README.md/shell-command.png)
    - Restart the terminal for the new $PATH value to take effect. You'll be able to type 'code .' in any folder to start editing files in that folder.  
- Azure CLI 
  - [Azure CLI running on Windows](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli) or
  - [Azure CLI running on MacOS](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos) or
  - [Azure CLI running on Linux](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt)
- Git Client from here: https://git-scm.com/downloads


With this new version of the project, by default the dev container is not activated. When the developers open the project with Visual Studio Code, it won't launch the dev container. By default with the code in the main branch, the files .devcontainer/devcontainer.json and .devcontainer/docker-compose.yml are not present anymore. The files .devcontainer/workspace-prep/launchVSCode.bat (Windows Batch file) and .devcontainer/workspace-prep/launchVSCode.sh (Linux Bash file) will be used to create the files .devcontainer/devcontainer.json and .devcontainer/docker-compose.yml before launching Visual Studio Code in order to activate the dev container.

With the new version, it will be possible to open the following dev containers which will be built on your machine:
|Type of dev container | Description |
|---------------------|-------------|
|Base | Base conda environment |
|localspark | Local Spark environment |
|db-connect | Databricks Connect environment |
|JupyterLab | JupyterLab environment |
|All | Local Spark, Databricks Connect and JupyterLab environment |


Moreover, in order to decrease the time to build the dev container image, the dev container images are prebuilt and available in the Azure Container Registry repository. If the bandwidth of your Internet connection is over 100 Mb/s, it will be faster to build your local dev container image using the prebuilt images. Visual Studio Code will directly download the prebuilt images which have already been tested.  

Below the list of prebuilt images:

|Type of dev container | Description |
|---------------------|-------------|
|Prebuilt Base | Base conda environment |
|Prebuilt localspark | Local Spark environment |
|Prebuilt db-connect | Databricks Connect environment |
|Prebuilt JupyterLab | JupyterLab environment |
|Prebuilt All | Local Spark, Databricks Connect and JupyterLab environment |

### **Cloning the repository on your machine**

Follow the steps below to clone the repository on your machine.

1. Clone the repository on your machine (git command: "git clone https://github.com/flecoqui/data-dev-container.git")

```bash
    git clone https://github.com/flecoqui/data-dev-container.git
```

2. Change directory

```bash
    cd data-dev-container
```

In order to use those dev containers, you need to configure the dev containers for the connection to Databricks Cluster.
You need to create to configuration files: `configs/.env` and `configs/.databrickscfg`
### **Setting up the backend and building the pre-built images**

As for the pre-built dev containers the images are stored in Azure Container Registry and as some dev containers use databricks clusters, you may need to deploy Azure Container Registry and Azure Databricks Cluster before moving to the next steps.

Below the link to deploy the infrastructure (Azure Container Registry and Azure Databricks Cluster):  
- [Azure DevOps Pipeline to deploy the dev container infrastructure](#azure-devops-pipeline-to-deploy-the-dev-container-infrastructure)

Below the link to build the pre-built images:  
- [Azure DevOps Pipeline to build and push the dev container images](#azure-devOps-pipeline-to-build-and-push-the-dev-container-images)


### **Setting up `configs/.env`**

This file needs to be created from the `configs/.env.example` file and filled
up with your Databricks clusters details.

Take the following steps to get started.

1. Open this repository with VSCode.
2. Copy `.env.example` and rename it to `.env`.
3. Edit `.env` file. The dev container loads the defined variables into environment
   variables and uses them for Databricks Connect.
    - *`DATABRICKS_HOST`*: Databricks workspace URL, which looks like this
      `https://adb-1929978767532022.2.azuredatabricks.net/`.
    - *`DATABRICKS_ADDRESS`*: Should be the same value as `DATABRICKS_HOST`.
    - *`DATABRICKS_TOKEN`*: personal access token (PAT) token to Databricks workspace,
      which looks like this `dapi084545e5bc2ae3ad860f5e3217fb2e49`. If you need to obtain a
      new token, you can follow [these instructions](https://docs.databricks.com/dev-tools/api/latest/authentication.html).
    - *`DATABRICKS_API_TOKEN`*: Should be the same value as `DATABRICKS_TOKEN`.
    - *`DATABRICKS_CLUSTER_ID`*: Cluster ID of Databricks cluster, which looks like
      this `0806-030057-dross131`.
    - *`DATABRICKS_ORG_ID`*: Org ID. See ?o=orgId in URL, which looks like this `1929978767532022`.
    - *`DATABRICKS_PORT`*: Use `15001`.
    - *`SSH_PROFILE`*: The name of your SSH key where the file name follows `id_${SSH_PROFILE}`. 
    - *`ACRNAME`*: Azure Container Registry name for prebuilt dev containers (can be found in [Azure portal](portal.azure.com), start by typing `ACR` in the search bar at the top).
    - *`ACRLOGINSERVER`*: Azure Container Registry login server (Login server in the Azure portal ACR blade).
    - *`TAG`*: prebuilt image tag (e.g. `latest`).
    - *`PREFIX`*: prebuilt image prefix (e.g. `devcontainer-workspace-dev`).
    - *`TENANT`*: Azure tenant (e.g. `yourtenant.onmicrosoft.com`.
4. Open VSCode command palette (`ctrl+shift+p`) and select `Remote-Containers: Reopen in Container`.
   It will take a while for the first time as it builds a devcontainer.
5. Activate `db-connect` python environment with `conda activate db-connect`.
6. Run `databricks-connect test` and see if your setting for Databricks Connect with
   environment variables works.

### **Setting up `configs/.databrickscfg`**

This file needs to be created from the `configs/.databrickscfg.example` file
and filled up with your Databricks details.

1. Replace *`SSH_PROFILE`* with the name of your SSH key where the file name follows `id_${SSH_PROFILE}`.
2. Set *`host`* with the same value as *`DATABRICKS_HOST`* you set in `.env`.
3. Set *`token`* with the same value as *`DATABRICKS_TOKEN`* you set in `.env`.


### **Using Visual Studio Code with local dev container images**

Follow the steps below to open the project with a dev container built locally (base, db-connect, db-jlab, localspark, all) with Visual Studio Code: 

1. Navigate into in the folder called ".devcontainer/workspace-prep". Launch the batch file (launchVSCode.bat) if you run Visual Studio Code on Windows or bash file (launchVSCode.sh) if you run Visual Studio Code on Linux.   
    ![](./docs/img/README.md/vscode-explorer.png)  
    Once the script files will display a menu to select the dev container flavor you want to launch.  
    ![](./docs/img/README.md/vscode-menu.png)  
    Enter 0, 1, 2, 3, 4 to launch a dev container which will be built locally.          


       1.  Local build base (conda only)
       2.  Local build all (conda, db-connect, db-jlab, localspark)
       3.  Local build db-connect (conda, db-connect)
       4.  Local build db-jlab (conda, db-jlab)
       5.  Local build localspark (conda, localspark)


    These scripts will create a new devcontainer.json file and a new docker-conpose.yml file.
2. Once Visual Studio Code is launched, after few seconds a popup dialog box is displayed, asking to reopen the project in container mode, click on the button "Reopen in container"  
    ![](./docs/img/README.md/vscode-reopen.png)
3.  The Visual Studio Code will reopen the project in container mode. Click on the link "Starting Dev Container (show logs)" to display the logs.  
    ![](./docs/img/README.md/vscode-starting.png)
4.  After few minutes, the dev container is ready and you can open a terminal:  
    ![](./docs/img/README.md/vscode-logs.png)
5.  Select the submenu "New Terminal" in the menu "Terminal" to open a terminal with the dev container:  
    ![](./docs/img/README.md/vscode-terminal.png)
6.  In the new terminal, you can use conda to activate the environment you selected at step 5: base, db-connect, db-jlab, localspark, all:  
    ![](./docs/img/README.md/vscode-bash.png)

### **Using Visual Studio Code with prebuilt dev container images**

Follow the steps below to open the project with a prebuilt dev container stored in Azure Container Registry  (base, db-connect, db-jlab, localspark, all) with Visual Studio Code: 

1. Navigate into in the folder called ".devcontainer/workspace-prep". Launch the batch file (launchVSCode.bat) if you run Visual Studio Code on Windows or bash file (launchVSCode.sh) if you run Visual Studio Code on Linux.   
    ![](./docs/img/README.md/vscode-explorer.png)  
    Once the script files will display a menu to select the dev container flavor you want to launch.  
    ![](./docs/img/README.md/vscode-menu.png)  
    Enter 5, 6, 7, 8, 9 to launch a dev container which will pulled from the Azure Container Registry.          


         1.  Prebuilt base (conda only)
         2.  Prebuilt all (conda, db-connect, db-jlab, localspark)
         3.  Prebuilt db-connect (conda, db-connect)
         4.  Prebuilt db-jlab (conda, db-jlab)
         5.  Prebuilt localspark (conda, localspark)


    These scripts will create a new devcontainer.json file and a new docker-conpose.yml file.
2. Once Visual Studio Code is launched, after few seconds a popup dialog box is displayed, asking to reopen the project in container mode, click on the button "Reopen in container"  
    ![](./docs/img/README.md/vscode-reopen.png)
3. The Visual Studio Code will reopen the project in container mode. Click on the link "Starting Dev Container (show logs)" to display the logs.  
    ![](./docs/img/README.md/vscode-starting.png)
4.  After few minutes, the dev container is ready and you can open a terminal:  
    ![](./docs/img/README.md/vscode-logs.png)
5. Select the submenu "New Terminal" in the menu "Terminal" to open a terminal with the dev container:  
    ![](./docs/img/README.md/vscode-terminal.png)
6.  In the new terminal, you can use conda to activate the environment you selected at step 6: base, db-connect, db-jlab, localspark, all:  
    ![](./docs/img/README.md/vscode-bash.png)


### **Files used to support locally built and prebuilt dev containers with Visual Studio Code**
  
    
&nbsp;
&nbsp;
&nbsp;

#### **Visual Studio Code dev container files supporting local db-connect, db-jlab and localspark conda environments**


| Path |  Type of file  &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;| Description   |
| :--- | :--- | :--- |
| .devcontainer/workspace-prep/devcontainer.prep.build.json |  JSON file | Devcontainer JSON template file used by Visual Studio Code to locally build devcontainers     |
| .devcontainer/workspace-prep/devcontainer.prep.prebuilt.json |  JSON file | Devcontainer JSON template file used by Visual Studio Code to pull prebuilt devcontainers from Azure Container Registry     |
| .devcontainer/workspace-prep/docker-compose.prep.build.yml | YAML file | Docker Compose template file used by Visual Studio Code to locally build devcontainers   |
| .devcontainer/workspace-prep/docker-compose.prep.prebuilt.yml | YAML file | Docker Compose template file used by Visual Studio Code to pull prebuilt devcontainers from Azure Container Registry   |
| .devcontainer/Dockerfile-all | Docker file | Docker file used to build the Devcontainer ('all' flavor) supporting db-connect, db-jlab and localspark conda environments used by Visual Studio Code   |
| .devcontainer/Dockerfile-base | Docker file | Docker file used to build the Devcontainer ('base' flavor) supporting conda without any preinstalled environment |
| .devcontainer/Dockerfile-db_connect | Docker file | Docker file used to build the Devcontainer ('db_connect' flavor) supporting db-connect conda environments used by Visual Studio Code |
| .devcontainer/Dockerfile-db_jlab | Docker file | Docker file used to build the Devcontainer ('db_jlab' flavor) supporting db-jlab conda environments used by Visual Studio Code |
| .devcontainer/Dockerfile-localspark | Docker file | Docker file used to build the Devcontainer ('localspark' flavor) supporting localspark conda environment used by Visual Studio Code |
| .devcontainer/workspace-prep/launchVSCode.bat | batch file | Windows Batch file used to launch Visual Studio Code with the selected devcontainer flavor. This batch file creates the files .devcontainer/devcontainer.json and .devcontainer/docker-compose.yml from the template files in the folder .devcontainer/workspace-prep replacing the string ${FLAVOR} in the template files with the selected flavor.    |
| .devcontainer/workspace-prep/launchVSCode.sh | bash file | Linux Bash file used to launch Visual Studio Code using the default local devcontainer. This batch file creates the files .devcontainer/devcontainer.json and .devcontainer/docker-compose.yml from the template files in the folder .devcontainer/workspace-prep replacing the string ${FLAVOR} in the template files with the selected flavor. |

&nbsp;
&nbsp;
&nbsp;




## Azure DevOps Pipeline to deploy the dev container infrastructure

### **Pre-requisites**
As the pre-built dev containers images will be stored in Azure Container Registry, an Azure Container Registry will be deployed in your environment("dev"). This new Azure Service will be deployed using an Azure DevOps pipeline.
A Azure Databricks Cluster will deployed as well to test the databricks Connect from your dev containers.

Before creating and launching this pipeline, some pre-requisites are required:
- An Azure DevOps account (portal url: https://dev.azure.com/YOUR-ORG/)
- A Service Connection which will be used by the infrastructure pipeline for the authentication with Azure
- The variables in the "dev" variable group. Those variables will be used by the infrastrucuture pipeline to initialize the pipeline configuration.  

Moreover, as the source code is stored on github, you need to link your github repository with your Azure DevOps account:

1. On the github portal, select the repository where you stored the source code of the project. Navigate to 'Settings' and 'Integrations'.
 ![](./docs/img/README.md/github-azure.png)
2. Click on the button 'Configure'
3. On the subsequent page, confirm your github password
4. On the Azure pipeline page, in the Repository access section, select your repository where the source code is stored. And click on the button 'Save'.
![](./docs/img/README.md/github-azure-01.png)
5. Then you are reditected to Azure DevOps, where you can create or select an existing organization for your project, and you can also create a project  or select an existing project. The Azure DevOps project will be called 'data-dev-container'  
![](./docs/img/README.md/github-azure-02.png)  

Once the project 'data-dev-container' is created, the AZure DevOps project will be accessible through this url: 
https://dev.azure.com/YOUR-ORG/data-dev-container
where YOUR-ORG is the devops organization you selected or created.


You are now ready to create the pipelines.


#### **Create the Service Connection which will be associated with the infrastructure pipeline**

As the infrastructure pipeline will deploy new resources in Azure Subscription, the pipeline will establish a connection with Azure using a Service Connection.
This Service Connection called "vsdcProject-dev-container-service-connection" will be created by the Contoso Administrator.
You can check if this Service Connection exists, if you follow the steps below: 
1.  Open the Azure DevOps portal with your favorite brower, using the following url:   
    <https://dev.azure.com/YOUR-ORG/data-dev-container>  
    ![](./docs/img/README.md/ProjectSettings.png)
2.  Click on "Project settings" link. 
   
3.  On the "Project Settings" page, click on "Service Connections" link  
    ![](./docs/img/README.md/serviceconnection.png)
4.  On the "Service Connections" page, click on the button 'New service connection':  
    ![](./docs/img/README.md/newserviceconnection.png)
5.  On the "New Service Connections" page, select 'Azure Resource Manager' and click on the button 'Next':  
    ![](./docs/img/README.md/newserviceconnection01.png)
6.  On the "New Service Connections" page, select 'Service principal (automatic)' and click on the button 'Next':  
    ![](./docs/img/README.md/newserviceconnection02.png)
7.  On the "New Service Connections" page, select the Azure subscription in the combo box 'subscription', enter the name of your service conneciton 'data-dev-container-sc' and click on the button 'Save':  
    ![](./docs/img/README.md/newserviceconnection03.png)
8.  On the "New Service Connections" page, select the Azure subscription in the combo box 'subscription', enter the name of your service conneciton 'data-dev-container-sc' and click on the button 'Save':  
    ![](./docs/img/README.md/newserviceconnection03.png)
9.  After few seconds the service connection is created and visible in the list:
    ![](./docs/img/README.md/newserviceconnection04.png)

Now we can define the variable group which will be used to store all the variables required for the deployment.
#### **Add/Update the variables in Variable Group "dev"**

The infrastructure pipeline will be initialized with variables defined in the variable group "dev". You can add/update the infrastructure variables following the steps below:

1.  Open the Azure DevOps portal with your favorite brower, using the following url:  
    <https://dev.azure.com/YOUR-ORG/data-dev-container>
2.  Click on "Library" link in the "Pipelines" panel.  
    ![](./docs/img/README.md/variablegroups.png)
3.  Click on the button "+ Variable Group" link in the "Library" page, to create the new variable group.  
    ![](./docs/img/README.md/variablegroups01.png)
4.  On the "Library" page, enter the name of the variable group 'dev': \
    ![](./docs/img/README.md/variablegroups02.png)

  
    
    | Variables | Description |
    |---------------------|-------------|
    | serviceConnection | Use the following service connection name so far: "data-dev-container-sc"  |
    | subscriptionId | The Contoso subscription id. You can get this value with Azure CLI using the following command when you are connected to the subscription: "az account show --query id"               |
    | businessUnit | So far the value is "contoso", this value is used while naming the resources |
    | serviceName | So far the value is "deco", this value is used while naming the resources  |
    | region | The Azure region where the services will be deployed. For instance: "eastus2"  |
    | tags | The tags which will be associated with the resource group which will be created. By default we use those tags:  "{'project=data-dev-container','env=dev'}"|
    | databricksClusterSparkVersion | Databricks Spark version. For instance: '7.3.x-cpu-ml-scala2.12' |
    | databricksClusterNodeType | Databricks cluster node type. For instance: 'Standard_F8s' |
    | databricksClusterName | Databricks cluster name. For instance: 'devcondatabricks01' |
    | databricksClusterMinWorkers | Min workers. For instance: 2 |
    | databricksClusterMaxWorkers | Max workers. For instance: 4 |
    | databricksClusterAutoTerminationMinutes | Auto Termination time in minutes. For instance: 30 | 
   
5.  Once the variables are added/updated don't forget to click on the "Save" button.\
    ![](./docs/img/README.md/variablegroups03.png)


### **Create and launch the dev container infrastructure pipeline**


1.  You are now ready to create the infrastructure pipeline. On the Azure DevOps portal
    navigate to your project where the pipeline will be stored:\
    <https://dev.azure.com/YOUR-ORG/data-dev-container>  

    ![](./docs/img/README.md/Pipeline.png)

2.  Select Pipelines and click on "New pipeline":\
    ![](./docs/img/README.md/Pipeline01.png)

3.  Select Github YAML\
    ![](./docs/img/README.md/Pipeline02.png)

4.  Select your github repository  
    ![](./docs/img/README.md/Pipeline03.png)

5.  Select Existing Azure Pipeline YAML file\
    ![](./docs/img/README.md/Pipeline04.png)

6.  Select the path in the repository to the yaml file (/pipelines/azure-dev-ops/azure-pipelines.devcontainer-infrastructure.yml) and click on the 'Continue' button:\
    ![](./docs/img/README.md/PipelineInfra05.png)

7.  Save the pipeline \
    ![](./docs/img/README.md/PipelineInfraSave.png)


8.  Then Rename the pipeline selecting 'Rename/move' menu\
    ![](./docs/img/README.md/PipelineInfraRename.png)

9.  Enter the new name and click on Save button\
    ![A screenshot of a cell phone Description automatically
    generated](./docs/img/README.md/PipelineInfraRenameSave.png)

10. You can now run the pipeline, click on "Run pipeline"\
    ![A close up of a logo Description automatically
    generated](./docs/img/README.md/PipelineInfraRun.png)

11. Select the Branch to run the pipeline:\
    ![](./docs/img/README.md/PipelineInfraRunBranch.png)

12.  The pipeline is now  deploying the infrastructure. After few minutes, the infrastructure is deployed: \
    ![](./docs/img/README.md/PipelineInfraDeployed.png) 
    

13.  You can click on "Deploy Container Registry" to get detailed information about the deployment:\
    ![](./docs/img/README.md/PipelineInfraDeployedDetail.png)

14.  At least, you can check on the Azure Portal, the Azure Container Registry and the Azure Databricks Services are deployed in the resource group called 'rg-businessUnit-serviceName-dev-gbl'.  
    ![](./docs/img/README.md/PipelineInfraAzure.png)

The dev container infrastructure and the databricks cluster are now deployed, you can create the dev container pipeline to build and push the new dev container images to the Azure Container Registry.


### **Devcontainer infrastructure pipeline files**

| Path | Type of file | Description |
|-------------------------------------------------------------------------|--------------------|---------------------------|
| pipelines/azure-dev-ops/azure-pipelines.devcontainer-infrastructure.yml | pipeline YAML file | Devcontainer infrastructure pipeline   |
| pipelines/azure-dev-ops/templates/azure-container-registry-infrastructure-pipeline.template.yml | template pipeline YAML file | Devcontainer Azure Container Registry infrastructure template pipeline   |
| pipelines/azure-dev-ops/templates/azure-databricks-infrastructure-pipeline.template.yml | template pipeline YAML file | Devcontainer Azure Databricks infrastructure template pipeline   |
| pipelines/azure-dev-ops/templates/deployment-gate.yml | template pipeline YAML file | Deployment Gate template pipeline   |
| pipelines/utils/arm/global-acr.json | ARM Template | Azure Container registry ARM template |
| pipelines/utils/arm/global-databricks.json | ARM Template | Azure Databricks ARM template |
| pipelines/utils/utils.sh | Bash | Bash file used to provide the azure resource name with function createResourceName |
| pipelines/utils/common-script.sh | Bash | Bash file used to initialize all the azure resource names |
| pipelines/utils/deploy-databricks.sh | Bash | Bash file used to deploy Azure Databricks |
| pipelines/utils/deploy-acr.sh | Bash | Bash file used to deploy Azure Container Registry |
| pipelines/utils/get-acr-info.sh | Bash | Bash file used to export  Azure Container Registry information (Password, Token, Name ) into the Variable Group "dev" once the container registry is deployed |

## Azure DevOps Pipeline to build, test and push the dev container images

### **Pre-requisites**
This pipeline will build the dev container images from the Azure DevOps repository and push those images to Azure Container Registry.
Before creating and launching this pipeline, some pre-requisites are required:
- An Azure DevOps account (portal url: https://dev.azure.com/YOUR-ORG/)
- A Service Connection which will be used by the infrastrucuture pipeline for the authentication with Azure
- The variables in the "dev" variable group. Those variables will be used by the dev container to initialize the pipeline configuration.  


#### **Create the Service Connection which will be associated with the infrastructure pipeline**

As the infrastructure pipeline will deploy new resources in Azure Subscription, the pipeline will establish a connection with Azure using a Service Connection.
This Service Connection called "data-dev-container-sc" will be created by the Contoso Administrator.
You can check if this Service Connection exists, if you follow the steps below: 
1.  Open the Azure DevOps portal with your favorite brower, using the following url:  
    <https://dev.azure.com/YOUR-ORG/data-dev-container>  
    ![](./docs/img/README.md/ProjectSettings.png)
2.  Click on "Project settings" link.  
    
3.  On the "Project Settings" page, click on "Service Connections" link  
    ![](./docs/img/README.md/serviceconnection.png)
4.  On the "Service Connections" page, you should see the "data-dev-container-sc" service connection:  
    ![](./docs/img/README.md/newserviceconnection04.png)

#### **Add/Update the variables in Variable Group "dev"**

The infrastructure pipeline will be initialized with variables defined in the variable group "dev". You can add/update the dev container variables following the steps below:

1.  Open the Azure DevOps portal with your favorite brower, using the following url: \
    <https://dev.azure.com/YOUR-ORG/data-dev-container>
2.  Click on "Library" link in the "Pipelines" panel. \
    ![](./docs/img/README.md/variablegroups.png)
3.  Click on the "dev" link in the "Library" page \
    ![](./docs/img/README.md/dev.png)
4.  On the "dev" page, you need to add/update the following variables: \

    | Variables | Description |
    |---------------------|-------------|
    | serviceConnection | Use the following service connection name so far: "vsdcProject-dev-container-service-connection"  |
    | subscriptionId | The Contoso subscription id. You can get this value with Azure CLI using the following command when you are connected to the subscription: "az account show --query id"               |
    | businessUnit | So far the value is "contoso", this value is used while naming the resources |
    | serviceName | So far the value is "vsdc", this value is used while naming the resources  |
    | region | The Azure region where the services will be deployed: "uaenorth"  |
    | repositoryUrl | The url of the Azure DevOps repository where the dev container is stored. This url has the following format: https://projectUrl#branch:path. For instance: https://github.com/flecoqui/data-dev-container.git#main:.devcontainer  |
    | dockerFilePrefix | The dockerfile prefix used the create the Dockerfile name for all the flavors: base, db_connect, db_jlab, localspark, all. The files are stored under .devcontainer folder: Dockerfile, Dockerfile-base, Dockerfile-localspark, Dockerfile-db_connect, Dockerfile-db-jlab. For instance: Dockerfile  |
    | repositoryToken | The Personal Access Token for the Azure DevOps repository. Check the link to [Create Personal Access Token on Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page#create-a-pat) or [Create Personal Access Token on Github](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)  |
    | imageNamePrefix | The dev container image name prefix, for instance: "data-dev-container_devcontainer_workspace". The image name for db-connect will be  "data-dev-container_devcontainer_workspace-db_connect". It's recommended to use this value: 'data-dev-container_devcontainer_workspace' to be sure the local image names match with the image names on the Azure Container Registry   |
    | basePipVersion | The expected pip version for the base conda environment. The value returned by the command "pip --version". This value is used for the unit tests. For instance: '20.2.4' |
    | localsparkPipVersion | The expected pip version for the localspark conda environment. The value returned by the command "pip --version". This value is used for the unit tests. For instance: '21.0.1' |
    | dbjlabPipVersion | The expected pip version for the db-jlab conda environment. The value returned by the command "pip --version". This value is used for the unit tests. For instance: '21.0.1'  |
    | dbconnectPipVersion | The expected pip version for the db-connect conda environment. The value returned by the command "pip --version". This value is used for the unit tests. For instance: '21.0.1'  |
  
    
   
5.  Once the variables are added/updated don't forget to click on the "Save" button.\
    ![](./docs/img/README.md/devSave.png)


### **Create and launch the dev container build pipeline**

1.  You are now ready to create the dev container build pipeline. On the Azure DevOps portal
    navigate to your project where the pipeline will be stored:\
    <https://dev.azure.com/YOUR-ORG/data-dev-container>  
    ![](./docs/img/README.md/Pipeline.png)  

2.  Select Pipelines and click on "New pipeline":\
    ![](./docs/img/README.md/Pipeline01.png)

3.  Select Github YAML\
    ![](./docs/img/README.md/Pipeline02.png)

4.  Select your github repository  
    ![](./docs/img/README.md/Pipeline03.png)

5.  Select Existing Azure Pipeline YAML file\
    ![](./docs/img/README.md/Pipeline04.png)

6.  Select the path in the repository to the yaml file (/pipelines/azure-dev-ops/azure-pipelines.devcontainer-build.yml) and click on the button 'Continue':\
    ![](./docs/img/README.md/PipelineBuildBranch.png)

7.  Save the pipeline \
    ![A screenshot of a cell phone Description automatically
    generated](./docs/img/README.md/PipelineInfraSave.png)


8.  Then Rename the pipeline selecting 'Rename/move' menu\
    ![](./docs/img/README.md/PipelineInfraRename.png)

9.  Enter the new name and click on Save button\
    ![A screenshot of a cell phone Description automatically
    generated](./docs/img/README.md/PipelineBuildSave.png)

10. You can now run the pipeline, click on "Run pipeline"\
    ![](./docs/img/README.md/PipelineInfraRun.png)

11. Select the Branch to run the pipeline:\
    ![](./docs/img/README.md/PipelineBuildRunBranch.png)

12. The dev container Build pipeline started. It will take up-to 60 minutes to build all the dev containers (all, db-connect, db-jlab, localspark, base).\
    ![](./docs/img/README.md/PipelineBuildBuilt.png)

13. Once the dev containers have been built, you can check they are avaiable in the Container Registry.\
    ![](./docs/img/README.md/PipelineBuildACRRepositories.png)

14. For each repository you can check if the latest tag is also available. If the unit tests are successul with the latest build, the tag latest will be associated with this build. \
    ![](./docs/img/README.md/PipelineBuildACRRepository.png)


### **Devcontainer build pipeline files**

| Path | Type of file | Description |
|-------------------------------------------------------------------------|--------------------|---------------------------|
| pipelines/azure-dev-ops/azure-pipelines.devcontainer-build.yml | pipeline YAML file | Devcontainer build pipeline   |
| pipelines/azure-dev-ops/templates/devcontainer-build-pipeline.template.yml | template pipeline YAML file | Devcontainer build template pipeline: build, test and update tag of the container image in the container registry   |
| pipelines/utils/utils.sh | Bash | Bash file used to provide the azure resource name with function createResourceName |
| pipelines/utils/common-script.sh | Bash | Bash file used to initialize all the azure resource names |
| pipelines/utils/buildimage.sh | Bash | Bash file used to build the image using Azure Container Registry task |


## Next steps
In this repository, we shared resources to:
- Create and use a pipeline to deploy the dev container Azure infrastructure (Azure Container Registry and Databricks services)  
- Create and use a pipeline to build and push the dev container images to Azure Container Registry  
- Use dev container images locally built with Visual Studio Code  
- Use the pre-built dev container images stored in Azure Container Registry with Visual Studio Code  

This repository could be extended to describe how to use dev containers running in a virtual machine and used from Visual Studio Code running on your local machine.  
Currently this repository contains mainly Data Science dev container images, this repository could be extended to support other types of dev container images.  
