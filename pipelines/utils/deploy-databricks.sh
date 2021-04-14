#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script is used to get Key Vault secrets for the AIP non-prod infrastructure 
#- Support deploying to multiple regions as well as required global resources
#- Parameters are:
#- [-s] subscription - The subscription where the resources will reside.
#- [-u] businessUnit - The business unit used for resource naming convention.
#- [-a] serviceName - The service name used for resource naming convention.
#- [-e] env - The environment to deploy (ex: dev | test | prod).
#- [-r] region - region where the service will be deployed (ex: westus,eastus2).
#- [-w] tags - tags to be stored in databricks.
#- [-n] databricksClusterName - databricks cluster name.
#- [-v] databricksClusterSparkVersion - databricks cluster spark version.
#- [-t] databricksClusterNodeType - databricks cluster node type.
#- [-i] databricksClusterMinWorkers - databricks cluster min worker.
#- [-j] databricksClusterMaxWorkers - databricks cluster max worker.
#- [-q] databricksClusterAutoTerminationMinutes - databricks cluster auto termination in minutes.
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
    echo -e "\t-n \t Sets the databricks cluster name"
    echo -e "\t-w \t Sets the tags for databricks"
    echo -e "\t-v \t Sets the databricks cluster spark version"
    echo -e "\t-t \t Sets the databricks cluster node type"
    echo -e "\t-i \t Sets the databricks cluster min worker"
    echo -e "\t-j \t Sets the databricks cluster max worker"
    echo -e "\t-q \t Sets the databricks cluster auto termination in minutes"
    echo "Example:"
    echo -e "\tbash get-keys-aip-non-prod.sh -s <subscriptionID> -u contoso -a deco -e test -r eastus2 "
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


while getopts "s:u:a:e:r:n:v:w:t:i:j:q:hq" opt; do
    case $opt in
    s) subscription=$OPTARG ;;
    u) businessUnit=$OPTARG ;;
    a) serviceName=$OPTARG ;;
    e) env=$OPTARG ;;
    r) region=("${OPTARG//,/ }") ;;
    w) tags="$OPTARG" ;;
    n) databricksClusterName=$OPTARG ;;
    v) databricksClusterSparkVersion=$OPTARG ;;
    t) databricksClusterNodeType=$OPTARG ;;
    i) databricksClusterMinWorkers=$OPTARG ;;
    j) databricksClusterMaxWorkers=$OPTARG ;;
    q) databricksClusterAutoTerminationMinutes=$OPTARG ;;
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
if [[ $# -eq 0 || -z $subscription || -z $businessUnit || -z $serviceName ||  -z $env || -z $region  ||-z $databricksClusterName || -z $databricksClusterSparkVersion || -z $databricksClusterNodeType || -z $databricksClusterMinWorkers || -z $databricksClusterMaxWorkers ||-z $tags || -z $databricksClusterAutoTerminationMinutes ]]; then
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
echo "Azure Databricks Cluster Name: $databricksClusterName"
echo "Azure Databricks Cluster Spark Version:  $databricksClusterSparkVersion"
echo "Azure Databricks Cluster Node Type:  $databricksClusterNodeType"
echo "Azure Databricks Cluster Min Workers:  $databricksClusterMinWorkers"
echo "Azure Databricks Cluster Max Workers:  $databricksClusterMaxWorkers"
echo "Azure Databricks Cluster AutoTermination:  $databricksClusterAutoTerminationMinutes"

# Check if databricks managed resource group  already exists
# if already exists, use the existing databricks managed resource group name
databricksresult=$(az group list --query "[?starts_with(name,'rg-managed-databricks')].[name]" --output tsv 2>&1 | head -n 1) || true

# if Storage Account exists use the existing Storage Account Name
if [[ -n $databricksresult ]] ; then
    databricksManagedResourceGroupName=$databricksresult 
fi
echo
echo "Deploying Databricks to $resourceGroupName"
echo 
# Update tags for ARM Template
doublequotedtags=$(echo "$tags" | sed "s/'/\\\"/g" | sed "s/=/\\\": \\\"/g" ) 
databricksdep="databricks-$(timestamp)"
cmd="az deployment group create \
    --name $databricksdep \
    --resource-group $resourceGroupName \
    --subscription $subscription \
    --template-file ./arm/global-databricks.json \
    --output table \
    --parameters \
    pricingTier='premium' workspaceName=$databricksName managedResourceGroupName=$databricksManagedResourceGroupName  tags='$doublequotedtags' "
echo 
echo "$cmd"
echo 
eval "$cmd"

workspaceUrl=$(az deployment group  show --name "$databricksdep" --resource-group "$resourceGroupName" --query 'properties.outputs.workspaceUrl.value' --output tsv)

# Lifetime token for one month
lifetimeToken=2592000
workspaceId=$(az resource show \
  --resource-type Microsoft.Databricks/workspaces \
  -g "$resourceGroupName" \
  -n "$databricksName" \
  --query id -o tsv)

# Get a token for the global Databricks application.
# The resource name is fixed and never changes.
token_response=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d)
token=$(jq .accessToken -r <<< "$token_response")
# echo "Azure Databricks Token: $token"
# Get a token for the Azure management API
token_response=$(az account get-access-token --resource https://management.core.windows.net/)
azToken=$(jq .accessToken -r <<< "$token_response")
# echo "Azure management API Token: $azToken"

# Use both tokens in Databricks API call

# echo "List of clusters:"
# curl -sf https://$host/api/2.0/clusters/list \
#   -H "Authorization: Bearer $token" \
#   -H "X-Databricks-Azure-SP-Management-Token:$azToken" \
#   -H "X-Databricks-Azure-Workspace-Resource-Id:$wsId"

# You can also generate a PAT token. Note the quota limit of 600 tokens.
api_response=$(curl -sf https://"$workspaceUrl"/api/2.0/token/create \
  -H "Authorization: Bearer $token" \
  -H "X-Databricks-Azure-SP-Management-Token:$azToken" \
  -H "X-Databricks-Azure-Workspace-Resource-Id:$workspaceId" \
  -d "{ \"lifetime_seconds\": $lifetimeToken, \"comment\": \"Management Token\" }")
databricksToken=$(jq .token_value -r <<< "$api_response")
databricksHost="https://${workspaceUrl}"
echo "Databricks Token: $databricksToken"
echo "Databricks Host: $databricksHost"


echo
echo "Install Databricks client "
echo 
# activate environment
conda create --yes --quiet --name buildenv python=3.7.3
eval "$(conda shell.bash hook)"
conda activate buildenv
pip install databricks-cli

# Create databricks config file 
cat > "$HOME"/.databrickscfg << EOF
[DEFAULT]
host: https://${workspaceUrl}
token: ${databricksToken}
EOF
echo "Databricks configuration:"
cat "$HOME"/.databrickscfg

if [[ -z $databricksClusterSparkVersion || -z $databricksClusterNodeType || -z "$databricksClusterMinWorkers" || -z "$databricksClusterMaxWorkers" || -z "$databricksClusterAutoTerminationMinutes" ]]; then
    echo "Required parameters for Cluster creation are missing"
    usage
    exit 1
fi
    sed "s/<databricksClusterName>/$databricksClusterName/g" < ./databricks_cluster_template.json  \
    | sed "s/<databricksClusterSparkVersion>/$databricksClusterSparkVersion/g" \
    | sed "s/<databricksClusterMinWorkers>/$databricksClusterMinWorkers/g" \
    | sed "s/<databricksClusterMaxWorkers>/$databricksClusterMaxWorkers/g" \
    | sed "s/<databricksClusterNodeType>/$databricksClusterNodeType/g" \
    | sed "s/<databricksClusterAutoTerminationMinutes>/$databricksClusterAutoTerminationMinutes/g" > /tmp/conf.json

# shellcheck disable=SC2089
cmd="databricks clusters list --output JSON | jq -r '.clusters[] | select (.cluster_name == \"$databricksClusterName\")' | jq -r '.cluster_id'"
echo "$cmd"
databricksClusterId=$(eval "$cmd")
echo "databricksClusterId=${databricksClusterId}"
if [[ -z "${databricksClusterId}" ]] ; then
    echo "Creating Databricks Cluster..."
    echo "Databricks Cluster configuration: "
    cat /tmp/conf.json
    echo ""        
    databricksClusterId=$(databricks clusters create --json-file /tmp/conf.json | jq -r '.cluster_id')
    echo "Databricks Cluster Created"
else
    echo "Updating existing Databricks Cluster - cluster ID: ${databricksClusterId} ..."
    sed "s/<databricksClusterId>/$databricksClusterId/g" < /tmp/conf.json > /tmp/confupdate.json        
    echo "Databricks Cluster configuration: "
    cat /tmp/confupdate.json
    echo ""
    databricks clusters edit --json-file /tmp/confupdate.json
    echo "Databricks Cluster Updated"
fi
if [[ -z "${databricksClusterId}" ]] ; then
    echo "Cluster Creation failed, command: databricks clusters create --json-file /tmp/conf.json"
fi
echo "ClusterId: ${databricksClusterId}"

echo "Databricks Cluster operation completed"
