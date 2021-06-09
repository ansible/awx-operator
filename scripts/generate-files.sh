#!/bin/bash
## This script will auto-generate the templated files and bundle files 
## after changes to CRD template files. Please use this instead of manually
## updating the managed yaml files.  
##
## Example:
## TAG=0.10.0 ./generate-files.sh

TAG=${TAG:-''}
if [[ -z "$TAG" ]]; then
    echo "Set your \$TAG variable to your registry server."
    echo "export TAG=mytag"
    exit 1
fi

ansible-playbook ansible/chain-operator-files.yml
operator-sdk generate bundle --operator-name awx-operator --version $TAG
