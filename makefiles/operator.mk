# operator.mk — AWX Operator specific targets and variables
#
# This file is NOT synced across repos. Each operator maintains its own.

#@ Operator Variables

VERSION ?= $(shell git describe --tags 2>/dev/null || echo 0.0.1)
PREV_VERSION ?= $(shell git describe --abbrev=0 --tags $(shell git rev-list --tags --skip=1 --max-count=1) 2>/dev/null)
IMAGE_TAG_BASE ?= quay.io/ansible/awx-operator
NAMESPACE ?= awx
DEPLOYMENT_NAME ?= awx-operator-controller-manager

# Dev CR to apply after deployment
DEV_CR ?= dev/awx-cr/awx-openshift-cr.yml

# Custom configs to apply during post-deploy (secrets, configmaps, etc.)
DEV_CUSTOM_CONFIG ?= dev/secrets/custom-secret-key.yml dev/secrets/admin-password-secret.yml

# Feature flags
BUILD_IMAGE ?= true
CREATE_CR ?= true

# Teardown configuration
TEARDOWN_CR_KINDS ?= awx
TEARDOWN_BACKUP_KINDS ?= awxbackup
TEARDOWN_RESTORE_KINDS ?= awxrestore
OLM_SUBSCRIPTIONS ?=

##@ AWX Operator

.PHONY: operator-up
operator-up: _operator-build-and-push _operator-deploy _operator-wait-ready _operator-post-deploy ## AWX-specific deploy
	@:

##@ Utilities

.PHONY: print-%
print-%: ## Print any variable from the Makefile. Use as `make print-VARIABLE`
	@echo $($*)
