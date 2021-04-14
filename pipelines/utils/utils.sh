#!/bin/bash
##############################################################
#- function to create a timestamp string
##############################################################
function timestamp() {
    date +"%Y%m%dZ%H%M%S"
}

##############################################################
#- function used to convert a bash array to ARM array format
#- $n - The values to join
##############################################################
function toArmArray() {
    array=("$@")
    value=$(printf "\"%s\"", "${array[@]}")
    value="[${value%?}]"
    printf '%s' "$value"
}


#######################################################
#- function used to print out script usage
#######################################################
function genStorageActNameUsage() {
    echo
    echo "Arguments:"
    echo -e "\t-u\t Sets the business unit"
    echo -e "\t-a\t Sets the app name"
    echo -e "\t-e\t Sets the environment"
    echo -e "\t-r\t Sets the region"
    echo
    echo "Example:"
    echo -e "\t generateStorageAccountName -u company -a service -e test -r westus"
}

#######################################################
#- function used to generate the storage account name
#######################################################
function generateStorageAccountName() {
    # reset the index for the arguments locally for this function.
    local OPTIND 
    while getopts ":u:a:e:r:" opt; do
        case $opt in
        u) local businessUnit=${OPTARG//-/} ;;
        a) local appName=${OPTARG//-/} ;;
        e) local env=${OPTARG//-/} ;;
        r) local region=${OPTARG//-/} ;;
        :)
            echo "Error: -${OPTARG} requires a value" >&2
            exit 1
            ;;
        *)
            genStorageActNameUsage
            exit 1
            ;;
        esac
    done
    shift $((OPTIND - 1))

    # Validation
    if [[ -z $businessUnit || -z $appName || -z $env || -z $region ]]; then
        echo "Required parameters are missing"
        genStorageActNameUsage
        exit 1
    fi

    # Storage account names can only contain lowercase letters and numbers
    # they need to be unique globally! Another restriction is they need
    # to be between 3-24 in length, the approach we follow here
    # is to produce an MD5 hash and truncate the first 24 characters.
    storageActName="${businessUnit}${appName}${env}${region}"
    # Mac has md5 while Ubuntu has md5sum
    # running script based on OS
    if [[ "$(uname)" == "Darwin" ]]; then
        storageActName=$(echo -n "$storageActName" "$(date +"%Y%m%d%H%M%S")" | md5)
    else
        storageActName=$(echo -n "$storageActName" "$(date +"%Y%m%d%H%M%S")" | md5sum)
    fi

    # ensure all chars are lowercase
    storageActName=$(echo sa"${storageActName:0:22}" | tr "[:upper:]" "[:lower:]")

    # Return storage account name
    echo "$storageActName"
}
##############################################################################
#- function used to create a AzDO matrix from region list
#- $n - The regoins to join
##############################################################################
function toRegionMatrix() {
    regions=("${@//,/ }")

    for region in "${regions[@]}"; do
        output+="\"$region\": { \"region\": \"$region\" },"
    done

    result=$(printf %s "${output}")
    result="{${result%?}}"

    printf '%s' "$result"
}
#######################################################
#- function used to print out script usage
#######################################################
function createStorageActNameUsage() {
    echo
    echo "Arguments:"
    echo -e "\t-p\t Sets the prefix"
    echo -e "\t-u\t Sets the business unit"
    echo -e "\t-a\t Sets the app name"
    echo -e "\t-e\t Sets the environment"
    echo -e "\t-r\t Sets the region"
    echo
    echo "Example:"
    echo -e "\t createStorageActNameUsage -p sa -u company -a service -e test -r westus"
}

##############################################################################
#- function used to create storage account names from well known parameters
#- -p Prefix ex) sa, store
#- -u Business Unit
#- -a App Name
#- -e Environment ex) prod, staging, dev
#- -r Region ex) westus, centralus, eastus
##############################################################################
function createStorageAccountName() {
    # reset the index for the arguments locally for this function.
    local region=""
    local OPTIND 
    while getopts ":p:u:a:e:r:" opt; do
        case $opt in
        p) local prefix=${OPTARG} ;;
        u) local businessUnit=${OPTARG//-/} ;;
        a) local appName=${OPTARG//-/} ;;
        e) local env=${OPTARG//-/} ;;
        r) local region=${OPTARG//-/} ;;
        :)
            echo "Error: -${OPTARG} requires a value" >&2
            exit 1
            ;;
        *)
            createStorageActNameUsage
            exit 1
            ;;
        esac
    done
    shift $((OPTIND - 1))

    # Validation
    if [[ -z $prefix || -z $businessUnit || -z $appName || -z $env ]]; then
        echo "Required parameters are missing"
        genStorageActNameUsage
        exit 1
    fi

    # Storage account names can only contain lowercase letters and numbers
    # they need to be unique globally! Another restriction is they need
    # to be between 3-24 in length, the approach we follow here
    # is to produce an MD5 hash and truncate the first 24 characters.
    if [[ -z $region ]]; then
        storageActName="${businessUnit}${appName}${env}"
    else
        storageActName="${businessUnit}${appName}${env}${region}"
    fi
    # Mac has md5 while Ubuntu has md5sum
    # running script based on OS
    if [[ "$(uname)" == "Darwin" ]]; then
        storageActName=$(echo -n "$storageActName" "$(date +"%Y%m%d%H%M%S")" | md5)
    else
        storageActName=$(echo -n "$storageActName" "$(date +"%Y%m%d%H%M%S")" | md5sum)
    fi

    # ensure all chars are lowercase
    storageActName=$(echo "${prefix}""${storageActName:0:$((24-${#prefix}))}" | tr "[:upper:]" "[:lower:]")

    # Return storage account name
    echo "$storageActName"
}

##############################################################################
#- function used to create resource names from well known parameters
#- -p Prefix ex) rg, webapp, backned, ai
#- -u Business Unit
#- -a App Name
#- -e Environment ex) prod, staging, dev
#- -r Region ex) westus, centralus, eastus
##############################################################################
function createResourceName() {
    # reset the index for the arguments locally for this function.
    local OPTIND  
    local region=""
    while getopts ":p:u:a:e:r:" opt; do
        case $opt in
        p) local prefix=${OPTARG} ;;
        u) local businessUnit=${OPTARG//-/} ;;
        a) local appName=${OPTARG//-/} ;;
        e) local env=${OPTARG//-/} ;;
        r) local region=${OPTARG//-/} ;;
        :)
            echo "Error: -${OPTARG} requires a value" >&2
            exit 1
            ;;
        *)
            echo "Error: createResourceName" >&2
            exit 1
            ;;                
        esac
    done
    shift $((OPTIND - 1))

    # Validation
    if [[ -z $prefix || -z $businessUnit || -z $appName || -z $env ]]; then
        echo "Required parameters are missing"
        exit 1
    fi
    if [[ -z $region ]]; then
        echo "$prefix-$businessUnit-$appName-$env"
    else
        echo "$prefix-$businessUnit-$appName-$env-$region"
    fi
}
##############################################################################
#- function used to create dns resource names from well known parameters
#- -p Prefix ex) rg, webapp, backned, ai
#- -u Business Unit
#- -a App Name
#- -e Environment ex) prod, staging, dev
#- -r Region ex) westus, centralus, eastus
##############################################################################
function createDNSResourceName() {
    # reset the index for the arguments locally for this function.
    local region=""
    local OPTIND 
    while getopts ":p:u:a:e:r:" opt; do
        case $opt in
        p) local prefix=${OPTARG//-/} ;;
        u) local businessUnit=${OPTARG//-/} ;;
        a) local appName=${OPTARG//-/} ;;
        e) local env=${OPTARG//-/} ;;
        r) local region=${OPTARG//-/} ;;
        :)
            echo "Error: -${OPTARG} requires a value" >&2
            exit 1
            ;;
        *)
            echo "Error: createDNSResourceName" >&2
            exit 1
            ;;            
        esac
    done
    shift $((OPTIND - 1))

    # Validation
    if [[ -z $prefix || -z $businessUnit || -z $appName || -z $env ]]; then
        echo "Required parameters are missing"
        exit 1
    fi
   if [[ -z $region ]]; then
        echo "$prefix$businessUnit$appName$env"
    else
        echo "$prefix$businessUnit$appName$env$region"
    fi 
}

