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

VERSION=${VERSION:-$(make print-VERSION)}
PREV_VERSION=${PREV_VERSION:-$(make print-PREV_VERSION)}

BRANCH=publish-awx-operator-$VERSION
FORK=${FORK:-awx-auto}
GITHUB_TOKEN=${GITHUB_TOKEN:-$AWX_AUTO_GITHUB_TOKEN}

IMG_REPOSITORY=${IMG_REPOSITORY:-quay.io/ansible}

OPERATOR_IMG=$IMG_REPOSITORY/awx-operator:$VERSION
CATALOG_IMG=$IMG_REPOSITORY/awx-operator-catalog:$VERSION
BUNDLE_IMG=$IMG_REPOSITORY/awx-operator-bundle:$VERSION

COMMUNITY_OPERATOR_GITHUB_ORG=${COMMUNITY_OPERATOR_GITHUB_ORG:-k8s-operatorhub}
COMMUNITY_OPERATOR_PROD_GITHUB_ORG=${COMMUNITY_OPERATOR_PROD_GITHUB_ORG:-redhat-openshift-ecosystem}

# Build bundle directory
make bundle IMG=$OPERATOR_IMG

# Build bundle and catalog images
make bundle-build bundle-push BUNDLE_IMG=$BUNDLE_IMG IMG=$OPERATOR_IMG
make catalog-build catalog-push CATALOG_IMG=$CATALOG_IMG BUNDLE_IMGS=$BUNDLE_IMG BUNDLE_IMG=$BUNDLE_IMG IMG=$OPERATOR_IMG

# Set containerImage & namespace variables in CSV
sed -i.bak -e "s|containerImage: quay.io/ansible/awx-operator:devel|containerImage: ${OPERATOR_IMG}|g" bundle/manifests/awx-operator.clusterserviceversion.yaml
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

echo "-- Create branch on community-operators fork --"
git clone https://github.com/$COMMUNITY_OPERATOR_GITHUB_ORG/community-operators.git

mkdir -p community-operators/operators/awx-operator/$VERSION/
cp -r bundle/* community-operators/operators/awx-operator/$VERSION/
pushd community-operators/operators/awx-operator/$VERSION/

git checkout -b $BRANCH
git add ./
git status

message='operator [N] [CI] awx-operator'
commitMessage="${message} ${VERSION}"
git commit -m "$commitMessage" -s

git remote add upstream https://$GITHUB_TOKEN@github.com/$FORK/community-operators.git

git push upstream --delete $BRANCH || true
git push upstream $BRANCH

gh pr create \
  --title "operator awx-operator (${VERSION})" \
  --body "operator awx-operator (${VERSION})" \
  --base main \
  --head $FORK:$BRANCH \
  --repo $COMMUNITY_OPERATOR_GITHUB_ORG/community-operators
popd

echo "-- Create branch on community-operators-prod fork --"
git clone https://github.com/$COMMUNITY_OPERATOR_PROD_GITHUB_ORG/community-operators-prod.git

mkdir -p community-operators-prod/operators/awx-operator/$VERSION/
cp -r bundle/* community-operators-prod/operators/awx-operator/$VERSION/
pushd community-operators-prod/operators/awx-operator/$VERSION/

git checkout -b $BRANCH
git add ./
git status

message='operator [N] [CI] awx-operator'
commitMessage="${message} ${VERSION}"
git commit -m "$commitMessage" -s

git remote add upstream https://$GITHUB_TOKEN@github.com/$FORK/community-operators-prod.git

git push upstream --delete $BRANCH || true
git push upstream $BRANCH

gh pr create \
  --title "operator awx-operator (${VERSION})" \
  --body "operator awx-operator (${VERSION})" \
  --base main \
  --head $FORK:$BRANCH \
  --repo $COMMUNITY_OPERATOR_PROD_GITHUB_ORG/community-operators-prod
popd
