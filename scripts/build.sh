#!/bin/bash
## This script will be build 3 images awx-{operator,bundle,catalog}
## and push to the $REGISTRY specified.
##
## The goal is provide an quick way to build a test image.
##
## Example:
##
## git clone https://github.com/ansible/awx-operator.git
## cd awx-operator
## REGISTRY=registry.example.com/ansible TAG=mytag scripts/build.sh
##
## As a result, the $REGISTRY will be populated with 2 images
## registry.example.com/ansible/awx-operator:mytag
## registry.example.com/ansible/awx-operator-bundle:mytag
## registry.example.com/ansible/awx-operator-catalog:mytag

OPERATOR_IMAGE=${OPERATOR_IMAGE:-awx-operator}
BUNDLE_IMAGE=${BUNDLE_IMAGE:-awx-operator-bundle}
CATALOG_IMAGE=${CATALOG_IMAGE:-awx-operator-catalog}

verify_podman_binary() {
  if hash podman 2>/dev/null; then
      POD_MANAGER="podman"
  else
      POD_MANAGER="docker"
  fi
}

verify_operator_sdk_binary() {
  if hash operator-sdk 2>/dev/null; then
      OPERATOR_SDK="$(which operator-sdk)"
  else
      echo "operator-sdk binary not found."
      echo "Please visit https://sdk.operatorframework.io/docs/building-operators/ansible/installation"
      exit 1
  fi
}

verify_opm_binary() {
  if hash opm 2>/dev/null; then
      OPM_BINARY="$(which opm)"
  else
      echo "opm binary not found."
      echo "Please visit https://github.com/operator-framework/operator-registry/releases"
      exit 1
  fi
}

prepare_local_deploy() {
    echo "operator_image: $REGISTRY/$OPERATOR_IMAGE" > ansible/group_vars/all
    echo "operator_version: $TAG" >> ansible/group_vars/all
    echo "pull_policy: Always" >> ansible/group_vars/all
    ansible-playbook ansible/chain-operator-files.yml
}


REGISTRY=${REGISTRY:-''}
if [[ -z "$REGISTRY" ]]; then
    echo "Set your \$REGISTRY variable to your registry server."
    echo "export REGISTRY=quay.io/ansible"
    exit 1
fi

TAG=${TAG:-''}
if [[ -z "$TAG" ]]; then
    echo "Set your \$TAG variable to your registry server."
    echo "export TAG=mytag"
    exit 1
fi

build_operator_image() {
  echo "Building and pushing $OPERATOR_IMAGE image"
  $POD_MANAGER build . -f build/Dockerfile -t $REGISTRY/$OPERATOR_IMAGE:$TAG
  $POD_MANAGER push $REGISTRY/$OPERATOR_IMAGE:$TAG
}

build_bundle_image() {
  echo "Building and pushing $BUNDLE_IMAGE image"
  $POD_MANAGER build . -f bundle.Dockerfile -t $REGISTRY/$BUNDLE_IMAGE:$TAG
  $POD_MANAGER push $REGISTRY/$BUNDLE_IMAGE:$TAG
}

build_catalog_image() {
  echo "Building and pushing $CATALOG_IMAGE image"
  $OPM_BINARY index add --bundles $REGISTRY/$BUNDLE_IMAGE:$TAG --tag $REGISTRY/$CATALOG_IMAGE:$TAG
  $POD_MANAGER push $REGISTRY/$CATALOG_IMAGE:$TAG
}

generate_catalogsource_yaml() {
  echo "Creating CatalogSource YAML"
  cat > catalogsource.yaml << EOF
---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: awx-operator
  namespace: operators
spec:
  displayName: 'Ansible AWX Operator'
  image: "$REGISTRY/$CATALOG_IMAGE:$TAG"
  publisher: 'Ansible AWX Operator'
  sourceType: grpc
EOF

  echo "Now run: 'kubectl apply -f catalogsource.yaml' to update the operator"
  echo "Happy testing!"
}

verify_podman_binary
verify_operator_sdk_binary
verify_opm_binary
prepare_local_deploy
build_operator_image
build_bundle_image
build_catalog_image
generate_catalogsource_yaml
