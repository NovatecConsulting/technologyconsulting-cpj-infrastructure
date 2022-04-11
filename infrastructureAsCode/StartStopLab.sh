#!/bin/bash
set -e

if [ -z "$TF_VAR_labname" ] ;
then
    echo "environmentname is unset" ;
    exit 1;
fi

(
set -x 

CLUSTER_NAME=${TF_VAR_labname}aks
RESOURCE_GROUP=${TF_VAR_labname}
LOCATION=${TF_VAR_location}
MCAKS="MC_"${RESOURCE_GROUP}"_"${CLUSTER_NAME}"_"${LOCATION}

  case "$1" in
  start)
    # Your Start Code
    echo "start vmss of AKS"
    az vmss start -n $(az vmss list --resource-group $MCAKS --query "[].name" -o tsv ) --resource-group $MCAKS
    echo "start vms"
    VM_NAMES=$(az vm list -g $RESOURCE_GROUP --show-details --query "[?powerState=='VM deallocated'].{ name: name }" -o tsv)
    for NAME in $VM_NAMES
    do
        echo "Start $NAME"
        az vm start -n $NAME -g $RESOURCE_GROUP 
    done    
    ;;
  stop)
    # Your Stop Code
    echo "stop vmss of AKS"
    AKSSTOP=$(az vmss list --resource-group $MCAKS --query "[].name" -o tsv )
    az vmss deallocate -n $AKSSTOP --resource-group $MCAKS
  
    echo "stop vms"
    VM_NAMES=$(az vm list -g $RESOURCE_GROUP --show-details --query "[?powerState=='VM running'].{ name: name }" -o tsv)
    for NAME in $VM_NAMES
    do
        echo "Stopping $NAME"
        az vm deallocate -n $NAME -g $RESOURCE_GROUP --no-wait
    done
    ;;

  *)
    echo "Usage: $0 {start|stop}" >&2
    exit 1
    ;;
  esac
status=$?
[ $status -eq 0 ] && echo "Start/Stop Lab was successful" || exit $status
)
