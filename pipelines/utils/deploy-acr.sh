#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script is used to deploy the Azure Container Registry for devcontainer
#- Support deploying to multiple regions as well as required global resources
#- Parameters are:
#- [-s] subscription - The subscription where the resources will reside.
#- [-u] businessUnit - The business unit used for resource naming convention.
#- [-a] serviceName - The service name used for resource naming convention.
#- [-e] env - The environment to deploy (ex: dev | test | prod).
#- [-r] region - region where the service will be deployed (ex: westus,eastus2).
#- [-t] tags - tags to be stored in the resource group.

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
    echo -e "\t-t \t Sets the tags used to create resource group"
    echo
    echo "Example:"
    echo -e "\tbash deployinfra.sh -s <subscriptionID> -u contoso -a deco -e test -r eastus2 -t zipcod=22750 "
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

while getopts "s:u:a:e:r:t:hq" opt; do
    case $opt in
    s) subscription=$OPTARG ;;
    u) businessUnit=$OPTARG ;;
    a) serviceName=$OPTARG ;;
    e) env=$OPTARG ;;
    r) regions=("${OPTARG//,/ }") ;;
    t) tags="$OPTARG" ;;
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
if [[ $# -eq 0 || -z $subscription || -z $businessUnit || -z $serviceName || -z $tags || -z $env || -z $regions ]]; then
    echo "Required parameters are missing"
    usage
    exit 1
fi


# include common script to populate shared variables
source utils.sh
source common-script.sh

echo "Resource Group: $resourceGroupName"
echo "Business Unit: $businessUnit"
echo "Service Name: $serviceName"
echo "Environment: $env"
echo "Azure Container Registry Name: $acrName"

echo "Creating global resource Group: $resourceGroupName"
echo "with tags: $tags"
echo 

cmd="az group create --subscription $subscription --name $resourceGroupName --location ${regions[0]} --tags $tags --output table"
eval "$cmd"

#az group create \
#    --subscription $subscription \
#    --name $resourceGroupName \
#    --location ${regions[0]} \
#    --tags "${tags[@]}" \
#    --output table 

    
## Tags:    
#    --tags {'project=devcontainer','env=test'}
## "\"project\"=devcontainer" "\"env\"=test"


echo
echo "Deploying Azure Container Registry resource $acrName  to $resourceGroupName"
echo 
az deployment group create \
    --name "acr-$(timestamp)" \
    --resource-group "$resourceGroupName" \
    --subscription "$subscription" \
    --template-file ./arm/global-acr.json \
    --output table \
    --parameters \
    acrName="$acrName" 

# Get Azure Container Registry Username
acrUsername=$(az acr credential show  -n "$acrName" --query  username --output json)
echo "Azure Container Registry User Name: $acrUsername"
# Get Azure Container Registry Password
acrPassword=$(az acr credential show  -n "$acrName" --query passwords[0].value --output json)
echo "Azure Container Registry Password: ${acrPassword}"
# Get Azure Container Registry login Server
acrLoginServer=$(az acr show -n "$acrName" --query loginServer --output json)
echo "Azure login server: $acrLoginServer"

echo "##vso[task.setVariable variable=acrName]$acrName"
echo "Azure Container Registry Name: $acrName"   
echo "##vso[task.setVariable variable=acrUsername]$acrUsername"
echo "Azure Container Registry User Name: $acrUsername"   
echo "##vso[task.setVariable variable=acrPassword]$acrPassword"
echo "Azure Container Registry Password: $acrPassword"   
echo "##vso[task.setVariable variable=acrLoginServer]$acrLoginServer"
echo "Azure Container Registry Login Server: $acrLoginServer"   

echo "Azure Container Registry deployment completed"


