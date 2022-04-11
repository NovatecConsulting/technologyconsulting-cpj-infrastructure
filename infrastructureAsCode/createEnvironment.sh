#!/bin/bash
set -e

# this script requires reading SPIs & other secrets before running
# for example: tenant_id and Azure-Service-Principal can be read from Azure KeyVault
# a read task exposes that secrets as environment variable during the pipeline run
# they are set via "bash task environment variable parameter"
# if you want to run this script locally, please run prepareTerraform.sh

if [ -z "$TF_VAR_labname" ] ;
then
    echo "environmentname is unset" ;
    exit 1;
fi

(
    terraform init \
              -backend-config="key=${TF_VAR_labname}-components.tfstate" \
              -backend-config="access_key=${STATE_BLOBACCESSKEY}" \
              -backend-config="storage_account_name=${STATE_SAACCOUNTNAME}"
    export TF_VAR_clientid=${ARM_CLIENT_ID}
    export TF_VAR_clientsecret=${ARM_CLIENT_SECRET}
    terraform apply --auto-approve    
    
    status=$?
    [ $status -eq 0 ] && echo "IAC run successful" || exit $status
)
