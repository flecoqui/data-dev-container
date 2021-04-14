#!/bin/bash
# change sh file directory
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)
cd "$parent_path"

export FLAVOR=all
export PREBUILT=false

# Read variables in .env file
export $(grep ACRNAME ../../configs/.env)
export $(grep ACRLOGINSERVER ../../configs/.env)
export $(grep TAG ../../configs/.env)
export $(grep PREFIX ../../configs/.env)
export $(grep TENANT ../../configs/.env)

declare stop=0


while [ $stop == 0 ]; do
cat <<ENDOFMENU
Select you devcontainer flavor:
0.  Local build base (conda only)
1.  Local build all (conda, db-connect, db-jlab, localspark)
2.  Local build db-connect (conda, db-connect)
3.  Local build db-jlab (conda, db-jlab)
4.  Local build localspark (conda, localspark)
5.  Prebuilt base (conda only)
6.  Prebuilt all (conda, db-connect, db-jlab, localspark)
7.  Prebuilt db-connect (conda, db-connect)
8.  Prebuilt db-jlab (conda, db-jlab)
9.  Prebuilt localspark (conda, localspark)
Q.  Quit
ENDOFMENU
echo -n "Enter a number(0,1,2,3,4,5,6,7,8 or 9,Q)"
read choice
case $choice in
        0) FLAVOR=base 
           PREBUILT=false
           ;;
        1) FLAVOR=all 
           PREBUILT=false
           ;;
        2) FLAVOR=db_connect 
           PREBUILT=false
           ;;
        3) FLAVOR=db_jlab 
           PREBUILT=false
           ;;
        4) FLAVOR=localspark 
           PREBUILT=false
           ;;
        5) FLAVOR=base 
           PREBUILT=true
           ;;
        6) FLAVOR=all 
           PREBUILT=true
           ;;
        7) FLAVOR=db_connect 
           PREBUILT=true
           ;;
        8) FLAVOR=db_jlab 
           PREBUILT=true
           ;;
        9) FLAVOR=localspark 
           PREBUILT=true
           ;;
        Q)
            exit 1
            ;;
         esac
if [[ -n $FLAVOR  ]] ; then
    stop=1
fi 
done

if [ "$PREBUILT" == true ] ; then
    echo "You have selected workspace-$FLAVOR-prebuilt"
    # Azure login
    az login --tenant $TENANT
    # Azure Container Registry login
    az acr login -n $ACRNAME
    echo Updating prebuilt devcontainer.json
    Command="s/\${FLAVOR}/$FLAVOR/g"
    CommandRemoveLine="/\\\"python.formatting.provider\\\":\ \\\"black\\\"/d"

    if [[ $FLAVOR == db_jlab || $FLAVOR == all  || $FLAVOR == db_connect  || $FLAVOR == localspark  ]]  ; then
      cat ./devcontainer.prep.prebuilt.json | sed "$Command" > ../devcontainer.json
    else
      cat ./devcontainer.prep.prebuilt.json | sed "$Command" | sed "$CommandRemoveLine" > ../devcontainer.json
    fi  

    echo Updating prebuilt docker-compose.yml
    Command1="s/\${FLAVOR}/$FLAVOR/g"
    Command2="s/\${ACRLOGINSERVER}/$ACRLOGINSERVER/g"
    Command3="s/\${PREFIX}/$PREFIX/g"
    Command4="s/\${TAG}/$TAG/g"
    cat ./docker-compose.prep.prebuilt.yml \
      | sed "$Command1" \
      | sed "$Command2" \
      | sed "$Command3" \
      | sed "$Command4" \
      > ../docker-compose.yml


    echo Getting the ACR Repository Digest for image $PREFIX-$FLAVOR
    acrresult=$(az acr repository show-manifests --name $ACRNAME --repository $PREFIX-$FLAVOR --output json --query "([?contains(tags,'latest')].digest)[0]" --output json)
    acrresult=$(echo "$acrresult" | tr -d '"')
    echo "ACRDigest: $acrresult"

    echo Getting Container ID associated with the image to remove
    containerID=$(docker container list --all --filter "ancestor=$ACRNAME/$PREFIX-$FLAVOR" --format "{{.ID}}")
    echo "Local ContainerID: $containerID"

    echo Getting the local Docker Repository Digest for image $ACRLOGINSERVER/$PREFIX-$FLAVOR
    dockerresult=$(docker image inspect $ACRLOGINSERVER/$PREFIX-$FLAVOR --format "{{(index .RepoDigests 0)}}") 
    echo "Local Docker Digest: $dockerresult"


   if [ ! -z $dockerresult ] ; then
	   if [ ! -z $acrresult ] ; then
	      if [ ${dockerresult:(-64)} == ${acrresult:(-64)} ] ; then 
    		   echo Local devcontainer image up-to-date
    	   else
            if [ ! -z $containerID ] ; then
               echo Removing the local container ID: $containerID to force the update
               docker container rm $containerID
            fi
            echo Removing the local Docker image $PREFIX-$FLAVOR to force the update
            docker image rm -f $ACRLOGINSERVER/$PREFIX-$FLAVOR
         fi
      fi
   fi

else

   if [ $FLAVOR != base ] ; then
    echo Checking if base image already exists $PREFIX-base
    dockerresult=$(docker image inspect $PREFIX-base --format "{{(index .RepoTags 0)}}") 
    echo "Local Base Tag: $dockerresult"

    if [ -z $dockerresult ] ; then
        echo Updating build docker-compose.yml to build base image
        Command="s/\${FLAVOR}/base/g"
        cat ./docker-compose.prep.build.yml | sed $Command  > ../docker-compose.yml
        echo Building base image
        docker-compose --project-name data-dev-container_devcontainer -f ../docker-compose.yml build
    fi
   fi

    echo "You have selected workspace-$FLAVOR"
    echo Updating prebuilt devcontainer.json
    Command="s/\${FLAVOR}/$FLAVOR/g"
    CommandRemoveLine="/\\\"python.formatting.provider\\\":\ \\\"black\\\"/d"
    
    if [[ $FLAVOR == db_jlab || $FLAVOR == all  || $FLAVOR == db_connect  || $FLAVOR == localspark  ]]  ; then
      cat ./devcontainer.prep.build.json | sed "$Command" > ../devcontainer.json
    else
      cat ./devcontainer.prep.build.json | sed "$Command" | sed "$CommandRemoveLine" > ../devcontainer.json
    fi  
    echo Updating prebuilt docker-compose.yml
    Command="s/\${FLAVOR}/$FLAVOR/g"
    cat ./docker-compose.prep.build.yml | sed $Command  > ../docker-compose.yml
fi

echo Launching VS Code
code ../../.

