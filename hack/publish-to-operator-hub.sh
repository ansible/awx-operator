#!/bin/bash

# Create PR to Publish to community-operators and community-operators-prod
#
# * Create upstream awx-operator release
# * Check out tag (1.1.2).
# * Run VERSION=1.1.2 make bundle
# * Clone https://github.com/k8s-operatorhub/community-operators --branch main
# * mkdir -p operators/awx-operator/0.31.0/
# * Copy in manifests/ metadata/ and tests/ directories into operators/awx-operator/1.1.2/
# * Use sed to add in a replaces or skip entry. replace by default.
# * No need to update config.yaml
# * Build and Push operator and bundle images
# * Open PR or at least push to a branch so that a PR can be manually opened from it.
#
# Usage:
#   First, check out awx-operator tag you intend to release, in this case, 1.0.0
#   $ VERSION=1.1.2 PREV_VERSION=1.1.1 FORK=<your-fork> ./hack/publish-to-operator-hub.sh
#
# Remember to change update the VERSION and PREV_VERSION before running!!!


set -e

VERSION=${VERSION:-blah2}
PREV_VERSION=${PREV_VERSION:-blah1}
BRANCH=publish-awx-operator-$VERSION
FORK=${FORK:-fork}

IMG=quay.io/ansible/awx-operator:$VERSION
CATALOG_IMG=quay.io/ansible/awx-operator-catalog:$VERSION
BUNDLE_IMG=quay.io/ansible/awx-operator-bundle:$VERSION

# Set path variables
OPERATOR_PATH=${OPERATOR_PATH:-~/awx-operator}

# Build & Push Operator Image  # Not needed because it is done as part of the GHA release automation
# make docker-build docker-push IMG=$IMG

# Build bundle directory
rm -rf bundle/
make bundle IMG=$IMG

# Build bundle and catalog images
make bundle-build bundle-push BUNDLE_IMG=$BUNDLE_IMG IMG=$IMG
make catalog-build catalog-push CATALOG_IMG=$CATALOG_IMG BUNDLE_IMGS=$BUNDLE_IMG BUNDLE_IMG=$BUNDLE_IMG IMG=$IMG

# Set containerImage & namespace variables in CSV
sed -i.bak -e "s|containerImage: quay.io/ansible/awx-operator:devel|containerImage: quay.io/ansible/awx-operator:${VERSION}|g" bundle/manifests/awx-operator.clusterserviceversion.yaml
sed -i.bak -e "s|namespace: placeholder|namespace: awx|g" bundle/manifests/awx-operator.clusterserviceversion.yaml

# Add replaces to dependency graph for upgrade path
if ! grep -qF 'replaces: awx-operator.v${PREV_VERSION}' bundle/manifests/awx-operator.clusterserviceversion.yaml; then
  sed -i.bak -e "/version: ${VERSION}/a \\
  replaces: awx-operator.v$PREV_VERSION" bundle/manifests/awx-operator.clusterserviceversion.yaml
fi

# Rename CSV to contain version in name
mv bundle/manifests/awx-operator.clusterserviceversion.yaml bundle/manifests/awx-operator.v${VERSION}.clusterserviceversion.yaml

# Set Openshift Support Range (bump minKubeVersion in CSV when changing)
if ! grep -qF 'openshift.versions' bundle/metadata/annotations.yaml; then
  sed -i.bak -e "/annotations:/a \\
  com.redhat.openshift.versions: v4.11" bundle/metadata/annotations.yaml
fi

# Remove .bak files from bundle result from sed commands
find bundle -name "*.bak" -type f -delete

# -- Put up community-operators PR
cd $OPERATOR_PATH
git clone git@github.com:k8s-operatorhub/community-operators.git

mkdir -p community-operators/operators/awx-operator/$VERSION/
cp -r bundle/* community-operators/operators/awx-operator/$VERSION/
cd community-operators/operators/awx-operator/$VERSION/
pwd
ls -la

# Commit and push PR
git checkout -b $BRANCH
git add ./
git status

message='operator [N] [CI] awx-operator'
commitMessage="${message} ${VERSION}"
git commit -m "$commitMessage" -s

git remote add upstream git@github.com:$FORK/community-operators.git
git push upstream $BRANCH


# -- Put up community-operators-prod PR
# Reset directory
cd $OPERATOR_PATH

pwd

git clone git@github.com:redhat-openshift-ecosystem/community-operators-prod.git

mkdir -p community-operators-prod/operators/awx-operator/$VERSION/
cp -r bundle/* community-operators-prod/operators/awx-operator/$VERSION/
cd community-operators-prod/operators/awx-operator/$VERSION/

pwd
ls -la

# Commit and push PR
git checkout -b $BRANCH
git add ./
git status

message='operator [N] [CI] awx-operator'
commitMessage="${message} ${VERSION}"
git commit -m "$commitMessage" -s

git remote add upstream git@github.com:$FORK/community-operators-prod.git
git push upstream $BRANCH


# -- Print Links to Branches
echo "Commnity Operators: https://github.com/$FORK/community-operators/pull/new/$BRANCH"
echo "Commnity Operators Prod: https://github.com/$FORK/community-operators-prod/pull/new/$BRANCH"

# -- Cleanup

rm -rf $OPERATOR_PATH/community-operators
rm -rf $OPERATOR_PATH/community-operators-prod
