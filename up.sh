#!/bin/bash
# AWX Operator up.sh
# Purpose:
#   Build operator image from your local checkout, push to quay.io/youruser/awx-operator:dev, and deploy operator

# -- Usage
#   NAMESPACE=awx TAG=dev QUAY_USER=developer ./up.sh
#   NAMESPACE=awx TAG=dev QUAY_USER=developer PULL_SECRET_FILE=my-secret.yml ./up.sh

# -- User Variables
NAMESPACE=${NAMESPACE:-awx}
QUAY_USER=${QUAY_USER:-developer}
TAG=${TAG:-$(git rev-parse --short HEAD)}
DEV_TAG=${DEV_TAG:-dev}
DEV_TAG_PUSH=${DEV_TAG_PUSH:-true}
PULL_SECRET_FILE=${PULL_SECRET_FILE:-hacking/pull-secret.yml}

# -- Check for required variables
# Set the following environment variables
# export NAMESPACE=awx
# export QUAY_USER=developer

if [ -z "$QUAY_USER" ]; then
  echo "Error: QUAY_USER env variable is not set."
  echo "  export QUAY_USER=developer"
  exit 1
fi
if [ -z "$NAMESPACE" ]; then
  echo "Error: NAMESPACE env variable is not set. Run the following with your namespace:"
  echo "  export NAMESPACE=developer"
  exit 1
fi

# -- Container Build Engine (podman or docker)
ENGINE=${ENGINE:-podman}

# -- Variables
IMG=quay.io/$QUAY_USER/awx-operator
KUBE_APPLY="kubectl apply -n $NAMESPACE -f"

# -- Wait for existing project to be deleted
# Function to check if the namespace is in terminating state
is_namespace_terminating() {
    kubectl get namespace $NAMESPACE 2>/dev/null | grep -q 'Terminating'
    return $?
}

# Check if the namespace exists and is in terminating state
if kubectl get namespace $NAMESPACE 2>/dev/null; then
    echo "Namespace $NAMESPACE exists."

    if is_namespace_terminating; then
        echo "Namespace $NAMESPACE is in terminating state. Waiting for it to be fully terminated..."
        while is_namespace_terminating; do
            sleep 5
        done
        echo "Namespace $NAMESPACE has been terminated."
    fi
fi

# -- Create namespace
kubectl create namespace $NAMESPACE


# -- Prepare

# Set imagePullPolicy to Always
files=(
    config/manager/manager.yaml
)
for file in "${files[@]}"; do
  if grep -qF 'imagePullPolicy: IfNotPresent' ${file}; then
    sed -i -e "s|imagePullPolicy: IfNotPresent|imagePullPolicy: Always|g" ${file};
  fi
done

# Create redhat-operators-pull-secret if pull credentials file exists
if [ -f "$PULL_SECRET_FILE" ]; then
  $KUBE_APPLY $PULL_SECRET_FILE
fi

# Delete old operator deployment
kubectl delete deployment awx-operator-controller-manager

# Create secrets
$KUBE_APPLY dev/secrets/custom-secret-key.yml
$KUBE_APPLY dev/secrets/admin-password-secret.yml

# (Optional) Create external-pg-secret
# $KUBE_APPLY dev/secrets/external-pg-secret.yml


# -- Login to Quay.io
$ENGINE login quay.io

if [ $ENGINE = 'podman' ]; then
  if [ -f "$XDG_RUNTIME_DIR/containers/auth.json" ] ; then
    REGISTRY_AUTH_CONFIG=$XDG_RUNTIME_DIR/containers/auth.json
    echo "Found registry auth config: $REGISTRY_AUTH_CONFIG"
  elif [ -f $HOME/.config/containers/auth.json ] ; then
    REGISTRY_AUTH_CONFIG=$HOME/.config/containers/auth.json
    echo "Found registry auth config: $REGISTRY_AUTH_CONFIG"
  elif [ -f "/home/$USER/.docker/config.json" ] ; then
    REGISTRY_AUTH_CONFIG=/home/$USER/.docker/config.json
    echo "Found registry auth config: $REGISTRY_AUTH_CONFIG"
  else
    echo "No Podman configuration files were found."
  fi
fi

if [ $ENGINE = 'docker' ]; then
  if [ -f "/home/$USER/.docker/config.json" ] ; then
	  REGISTRY_AUTH_CONFIG=/home/$USER/.docker/config.json
    echo "Found registry auth config: $REGISTRY_AUTH_CONFIG"
  else
    echo "No Docker configuration files were found."
  fi
fi


# -- Build & Push Operator Image
echo "Preparing to build $IMG:$TAG ($IMG:$DEV_TAG) with $ENGINE..."
sleep 3

# Detect architecture and use multi-arch build for ARM hosts
HOST_ARCH=$(uname -m)
if [[ "$HOST_ARCH" == "aarch64" || "$HOST_ARCH" == "arm64" ]] && [ "$ENGINE" = "podman" ]; then
  echo "ARM architecture detected ($HOST_ARCH). Using multi-arch build..."
  make podman-buildx IMG=$IMG:$TAG ENGINE=$ENGINE
else
  make docker-build docker-push IMG=$IMG:$TAG

  # Tag and Push DEV_TAG Image when DEV_TAG_PUSH is 'True'
  if $DEV_TAG_PUSH ; then
    $ENGINE tag $IMG:$TAG $IMG:$DEV_TAG
    make docker-push IMG=$IMG:$DEV_TAG
  fi
fi

# -- Deploy Operator
make deploy IMG=$IMG:$TAG NAMESPACE=$NAMESPACE

# -- Create CR
# uncomment the CR you want to use
$KUBE_APPLY dev/awx-cr/awx-openshift-cr.yml
# $KUBE_APPLY dev/awx-cr/awx-cr-settings.yml
# $KUBE_APPLY dev/awx-cr/awx-k8s-ingress.yml

