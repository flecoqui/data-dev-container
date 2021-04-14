#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script is used to deploy the Lorentz service
#- Support deploying to multiple regions as well as required global resources
#- Parameters are:
#- [-s] subscription - The subscription where the resources will reside.
#- [-u] businessUnit - The business unit used for resource naming convention.
#- [-a] serviceName - The service name used for resource naming convention.
#- [-e] env - The environment to deploy (ex: dev | test | prod).
#- [-r] region - region where the service will be deployed (ex: westus,eastus2).
#- [-p] repository - repository where the code is stored.
#- [-d] dockerFilePath - Dockerfile path in the repository.
#- [-t] token - access token for the source code.
#- [-i] imageName - devcontainer image Name
###########################################################################################################################################################################################
set -eu
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)
cd "$parent_path"
#######################################################
#- function used to print out script usage
#######################################################
function usage() {
    echo
    echo "Arguments:"
    echo -e "\t-s\t Sets the subscription"
    echo -e "\t-u \t Sets the business unit (required)"
    echo -e "\t-a \t Sets the service name (required)"
    echo -e "\t-e \t Sets the environment (required)"
    echo -e "\t-r \t Sets the region list (Comma delimited values) (required)"
    echo -e "\t-o \t Sets the source code repository"
    echo -e "\t-d \t Sets the dockerFile path"
    echo -e "\t-k \t Sets the access token for the source code"
    echo -e "\t-i \t Sets the devcontainer image name"
    echo
    echo "Example:"
    echo -e "\tbash buildimage.sh -u haivision -a lorentz -e test -r eastus2 -o  https://flecoquiTestAzDO@dev.azure.com/flecoquiTestAzDO/TestNodeJsWebAppAKS/_git/TestNodeJsWebAppAKS#master:srtRegistry -d DockerFile -k pwh25dfygowhqeno3dmunso7dsbw4ypqkuyg4jsw35renup5zlna -i workspacedev"
}

while getopts "s:u:a:e:r:o:d:k:i:hq" opt; do
    case $opt in
    s) subscription=$OPTARG ;;
    u) businessUnit=$OPTARG ;;
    a) serviceName=$OPTARG ;;
    e) env=$OPTARG ;;
    r) regions=("${OPTARG//,/ }") ;;
    o) repository=$OPTARG ;;
    d) dockerFilePath=$OPTARG ;;
    k) token=$OPTARG ;;
    i) imageName=$OPTARG ;;
    :)
        echo "Error: -${OPTARG} requires a value"
        exit 1
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done

# Validation
# shellcheck disable=SC2128
if [[ $# -eq 0 || -z $subscription || -z $businessUnit || -z $serviceName || -z $env || -z $regions || -z $repository || -z $dockerFilePath || -z $token || -z $imageName ]]; then
    echo "Required parameters are missing"
    usage
    exit 1
fi


# include common script to populate shared variables
source utils.sh
source common-script.sh


# set global resource group name
resourceGroupName=$(createResourceName -p rg -u "$businessUnit" -a "$serviceName" -e "$env" -r gbl)

#imageName='devcontainer-'$serviceName
imageNameId=$imageName':{{.Run.ID}}'
imageTag='latest'
latestImageName=$imageName':'$imageTag
acrLoginServer=$(az acr show -n "$acrName" --query loginServer --output json)
imageNamePrefix=${imageName%-*}

echo "Resource Group: $resourceGroupName"
echo "Business Unit: $businessUnit"
echo "Service Name: $serviceName"
echo "Environment: $env"
echo "Azure Container Registry Name: $acrName"
echo "Azure Container Registry Login Server: $acrLoginServer"
echo "Image Name: $imageName"
echo "Image Name Id: $imageNameId"
echo "Latest Image Name: $latestImageName"

echo
echo "Create task to build devcontainer image: $businessUnit-$serviceName" 
echo

az acr task create  --image "$imageNameId"   -n "$businessUnit-$serviceName" -r "$acrName" --arg USERNAME=userddc --arg USER_UID=1000 --arg USER_GID=1000 \
    --arg PREFIX="$imageNamePrefix" --arg ACRLOGINSERVER="$acrLoginServer" --arg SEPARATOR=/ -c "$repository" \
    -f "$dockerFilePath" --git-access-token "$token"  --commit-trigger-enabled false --base-image-trigger-enabled false 
echo
echo "Launching the task to build service: $serviceName" 
echo
az acr task run  -n "$businessUnit-$serviceName" -r "$acrName"
tagIDwithQuotes=$(az acr task list-runs  --registry "$acrName" -n "$businessUnit-$serviceName" --query [0].runId) 
tagID=$(echo "$tagIDwithQuotes" | tr -d '"')
echo "Build Image Run ID: $tagID"
count=$(az acr task logs  -n "$businessUnit-$serviceName" -r "$acrName"  | grep -c "Run ID: $tagID was successful after") || true
if [[ $count = '1' ]]
then
    echo "Image successfully built"
    echo "Container deployment completed"	
    echo "Export Variables ImageNameId and ACR DNS name"	
    echo "##vso[task.setVariable variable=IMAGENAMEID]$imageName:$tagID"   
    echo "##vso[task.setVariable variable=ACRDNSNAME]$acrLoginServer"  
    echo "##vso[task.setVariable variable=ACRNAME]$acrName"      
else
    echo "Error while building the image"
    exit 1
fi
