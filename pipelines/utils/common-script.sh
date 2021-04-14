#!/bin/bash

##############################################################
#- This file holds the script commonly used across the
#- the solutions deployment scripts.
##############################################################

parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")" || return
    pwd -P
)
cd "$parent_path" || return

# shellcheck disable=SC2034,SC2154
{
# Deployment scopes
globalScope="$businessUnit-$serviceName-$env-gbl"

# Global configs
resourceGroupName=$(createResourceName -p rg -u "$businessUnit" -a "$serviceName" -e "$env" -r gbl)
acrName=$(createDNSResourceName -p acr -u "$businessUnit" -a "$serviceName" -e "$env" -r gbl)
databricksName=$(createResourceName -p databricks -u "$businessUnit" -a "$serviceName" -e "$env" -r db)
if [[ "$(uname)" == "Darwin" ]]; then
    databricksActName=$(echo -n "$databricksName" "$(date +"%Y%m%d%H%M%S")" | md5)
else
    databricksActName=$(echo -n "$databricksName" "$(date +"%Y%m%d%H%M%S")" | md5sum)
fi

# ensure all chars are lowercase
databricksActName=$(echo "${databricksActName:0:16}" | tr "[:upper:]" "[:lower:]")
databricksManagedResourceGroupName=$(createResourceName -p "rg-managed-databricks" -u "$businessUnit" -a "$serviceName"-"$databricksActName" -e "$env" )

# Regional configs
if [[ -n ${region+x} ]]; then
    regionScope="$businessUnit-$serviceName-$env-$region"
fi
}