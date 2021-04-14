#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script is used to get information from an existing Azure Container Registry
#- Parameters are:
#- [-s] subscription - The subscription where the resources will reside.
#- [-u] businessUnit - The business unit used for resource naming convention.
#- [-a] serviceName - The service name used for resource naming convention.
#- [-e] env - The environment to deploy (ex: dev | test | prod).
#- [-r] region - region where the service will be deployed (ex: westus,eastus2).
#- [-o] organization - Azure Devops Organization.
#- [-p] project - Azure Devops Project.
#- [-k] repositoryToken - Azure Devops Repository Token.
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
    echo -e "\t-o \t Sets the organization"
    echo -e "\t-p \t Sets the project"
    echo -e "\t-k \t Sets the repository Token"
    echo
    echo "Example:"
    echo -e "\tbash getacrinfo.sh -s <subscriptionID> -u contoso -a deco -e test -r eastus2 -o https://dev.azure.com/testuporg1/ -p TestUniversalPackageOrg1 -k td6qssmlojq5oi5o4ohuq2ci2e7dlbxb7mzsdu64r3rqjm7xyzja"
}

##############################################################################
#- function used to join a bash array into a string with specified delimiter
#- $1 - The delimiter
#- $n - The values to join
##############################################################################
function join() {
    local d=$1
    shift
    echo -n "$1"
    shift
    printf "%s" "${@/#/$d}"
}

while getopts "s:u:a:e:r:o:p:k:hq" opt; do
    case $opt in
    s) subscription=$OPTARG ;;
    u) businessUnit=$OPTARG ;;
    a) serviceName=$OPTARG ;;
    e) env=$OPTARG ;;
    r) regions=("${OPTARG//,/ }") ;;
    o) organization=$OPTARG ;;
    p) project=$OPTARG ;;
    k) repositoryToken=$OPTARG ;;
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
if [[ $# -eq 0 || -z $subscription || -z $businessUnit || -z $serviceName || -z $env || -z $regions || -z $organization || -z $project || -z $repositoryToken ]]; then
    echo "Required parameters are missing"
    usage
    exit 1
fi


# include common script to populate shared variables
source utils.sh
source common-script.sh

# set subscription ID
az account set --subscription "$subscription"

# set global resource group name
resourceGroupName=$(createResourceName -p rg -u "$businessUnit" -a "$serviceName" -e "$env" -r gbl)

echo "Resource Group: $resourceGroupName"
echo "Business Unit: $businessUnit"
echo "Service Name: $serviceName"
echo "Environment: $env"
echo "Azure Container Registry Name: $acrName"
echo "Azure DevOps Organization: $organization"
echo "Azure DevOps Project: $project"
echo "Azure DevOps Personal Access Token: $repositoryToken"


# Get Azure Container Registry Username
acrUsername=$(az acr credential show  -n "$acrName" --query  username --output json)
echo "Azure Container Registry User Name: $acrUsername"
# Get Azure Container Registry Password
acrPassword=$(az acr credential show  -n "$acrName" --query passwords[0].value --output json)
echo "Azure Container Registry Password has ${#acrPassword} characters"
# Get Azure Container Registry login Server
acrLoginServer=$(az acr show -n "$acrName" --query loginServer --output json)
echo "Azure login server: $acrLoginServer"

#az login

echo "Azure DevOps CLI login for organization: $organization and project: $project"
az extension add --name azure-devops
echo "$repositoryToken" | az devops login --organization "$organization"
az devops configure --defaults organization="$organization" project="$project"
echo "Azure DevOps List pipelines to check the connection"
listpipeline=$(az pipelines list --project "$project" --query [].name --output json)
echo "$listpipeline" 


echo "Getting Variable Group Id for $env: az pipelines variable-group list --group-name $env --org $organization --project $project --query [0].id --output json"
groupId=$(az pipelines variable-group list --group-name "$env" --org "$organization" --project "$project" --query [0].id --output json)
echo "Variable Group Id: $groupId"
echo "Updating value acrName=$acrName Variable Group $env "
value=$(az pipelines variable-group variable list --group-id "$groupId" --org "$organization" --project "$project"  --query acrName.value --output json)
if [[ -z $value ]]; then
    az pipelines variable-group variable create --group-id "$groupId" --org "$organization" --project "$project"  --name acrName --value "$acrName" || true
else
    az pipelines variable-group variable update --group-id "$groupId" --org "$organization" --project "$project"  --name acrName --value "$acrName" || true
fi
echo "Updating value acrLoginServer=$acrLoginServer Variable Group $env "
value=$(az pipelines variable-group variable list --group-id "$groupId" --org "$organization" --project "$project"  --query acrLoginServer.value --output json)
if [[ -z $value ]]; then
    az pipelines variable-group variable create --group-id "$groupId" --org "$organization" --project "$project"  --name acrLoginServer --value "$acrLoginServer" || true
else
    az pipelines variable-group variable update --group-id "$groupId" --org "$organization" --project "$project"  --name acrLoginServer --value "$acrLoginServer" || true
fi
echo "Variable Group $env variables acrName and acrLoginServer set"

echo "Updating value acrUsername=$acrUsername Variable Group $env "
value=$(az pipelines variable-group variable list --group-id "$groupId" --org "$organization" --project "$project"  --query acrUsername.value --output json)
if [[ -z $value ]]; then
    az pipelines variable-group variable create --group-id "$groupId" --org "$organization" --project "$project"  --name acrUsername --value "$acrUsername" || true
else
    az pipelines variable-group variable update --group-id "$groupId" --org "$organization" --project "$project"  --name acrUsername --value "$acrUsername" || true
fi
echo "Updating value acrPassword=$acrPassword Variable Group $env "
value=$(az pipelines variable-group variable list --group-id "$groupId" --org "$organization" --project "$project"  --query acrPassword.value --output json)
if [[ -z $value ]]; then
    az pipelines variable-group variable create --group-id "$groupId" --org "$organization" --project "$project"  --name acrPassword --value "$acrPassword" || true
else
    az pipelines variable-group variable update --group-id "$groupId" --org "$organization" --project "$project"  --name acrPassword --value "$acrPassword" || true
fi
echo "Variable Group $env variables acrUsername and acrPassword set"

