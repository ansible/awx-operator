# common.mk — Shared dev workflow targets for AAP operators
#
# Synced across all operator repos via GHA.
# Operator-specific customization goes in operator.mk.
#
# Usage:
#   make up        # Full dev deploy
#   make down      # Full dev undeploy
#
# Required variables (set in operator.mk):
#   NAMESPACE         — target namespace
#   DEPLOYMENT_NAME   — operator deployment name
#   VERSION           — operator version
#
# Optional overrides:
#   CONTAINER_TOOL=docker make up   # use docker instead of podman (default in Makefile)
#   QUAY_USER=myuser make up
#   DEV_TAG=mytag make up
#   DEV_IMG=registry.example.com/my-operator make up        # override image (skips QUAY_USER)
#   IMAGE_PULL_POLICY=Never make up                        # set imagePullPolicy (e.g. for local builds)
#   PODMAN_CONNECTION=aap-lab make up                      # use remote podman connection
#   KEEP_NAMESPACE=true make down   # undeploy but keep namespace
#   PLATFORM=linux/amd64 make up    # build for specific platform (auto-detected from cluster)
#   MULTI_ARCH=true make up         # build multi-arch image (PLATFORMS=linux/arm64,linux/amd64)

# Suppress "Entering/Leaving directory" messages from recursive make calls
MAKEFLAGS += --no-print-directory

#@ Common Variables

# Kube CLI auto-detect (oc preferred, kubectl fallback)
KUBECTL ?= $(shell command -v oc 2>/dev/null || command -v kubectl 2>/dev/null)

# Dev workflow
QUAY_USER ?=
REGISTRIES ?= registry.redhat.io $(if $(QUAY_USER),quay.io/$(QUAY_USER))
DEV_TAG ?= dev
PULL_SECRET_FILE ?= dev/pull-secret.yml
CREATE_PULL_SECRET ?= true
IMAGE_PULL_POLICY ?=
PODMAN_CONNECTION ?=

# Dev image: defaults to quay.io/<user>/<operator-name>, overridable via DEV_IMG
_OPERATOR_NAME = $(notdir $(IMAGE_TAG_BASE))
DEV_IMG ?= $(if $(QUAY_USER),quay.io/$(QUAY_USER)/$(_OPERATOR_NAME),$(IMAGE_TAG_BASE))

# Build platform (auto-detected from cluster, override with PLATFORM=linux/amd64)
MULTI_ARCH ?= false
PLATFORMS ?= linux/arm64,linux/amd64

# Auto-detect registry auth config
REGISTRY_AUTH_CONFIG ?= $(shell \
  if [ "$(CONTAINER_TOOL)" = "podman" ]; then \
    for f in "$${XDG_RUNTIME_DIR}/containers/auth.json" \
             "$${HOME}/.config/containers/auth.json" \
             "$${HOME}/.docker/config.json"; do \
      [ -f "$$f" ] && echo "$$f" && break; \
    done; \
  else \
    [ -f "$${HOME}/.docker/config.json" ] && echo "$${HOME}/.docker/config.json"; \
  fi)

# Container tool with optional remote connection (podman only)
_CONTAINER_CMD = $(CONTAINER_TOOL)$(if $(and $(filter podman,$(CONTAINER_TOOL)),$(PODMAN_CONNECTION)), --connection $(PODMAN_CONNECTION),)

# Portable sed -i (GNU vs BSD)
_SED_I = $(shell if sed --version >/dev/null 2>&1; then echo 'sed -i'; else echo 'sed -i ""'; fi)

# Custom configs to apply during post-deploy (secrets, configmaps, etc.)
DEV_CUSTOM_CONFIG ?=

# Dev CR to apply after deployment (set in operator.mk)
DEV_CR ?=
CREATE_CR ?= true

# Teardown configuration (set in operator.mk)
TEARDOWN_CR_KINDS ?=
TEARDOWN_BACKUP_KINDS ?=
TEARDOWN_RESTORE_KINDS ?=
OLM_SUBSCRIPTIONS ?=
DELETE_PVCS ?= true
DELETE_SECRETS ?= true
KEEP_NAMESPACE ?= false

##@ Dev Workflow

.PHONY: up
up: _require-img _require-namespace ## Full dev deploy
	@$(MAKE) registry-login
	@$(MAKE) ns-wait
	@$(MAKE) ns-create
	@$(MAKE) ns-security
	@$(MAKE) pull-secret
	@$(MAKE) patch-pull-policy
	@$(MAKE) operator-up

.PHONY: down
down: _require-namespace ## Full dev undeploy
	@echo "=== Tearing down dev environment ==="
	@$(MAKE) _teardown-restores
	@$(MAKE) _teardown-backups
	@$(MAKE) _teardown-operands
	@$(MAKE) _teardown-pvcs
	@$(MAKE) _teardown-secrets
	@$(MAKE) _teardown-olm
	@$(MAKE) _teardown-namespace

#@ Operator Deploy Building Blocks
#
# Composable targets for operator-up. Each operator.mk wires these
# together in its own operator-up target, adding repo-specific steps.
#
# Kustomize repos:
#   operator-up: _operator-build-and-push _operator-deploy _operator-wait-ready _operator-post-deploy
#
# OLM repos (gateway):
#   operator-up: _olm-cleanup _olm-deploy _operator-build-and-inject _operator-wait-ready <custom> _operator-post-deploy

.PHONY: _operator-build-and-push
_operator-build-and-push:
	@if [ "$(BUILD_IMAGE)" != "true" ]; then \
		echo "Skipping image build (BUILD_IMAGE=false)"; \
		exit 0; \
	fi; \
	$(MAKE) dev-build; \
	echo "Pushing $(DEV_IMG):$(DEV_TAG)..."; \
	$(_CONTAINER_CMD) push $(DEV_IMG):$(DEV_TAG)

.PHONY: _operator-deploy
_operator-deploy:
	@$(MAKE) pre-deploy-cleanup
	@cd config/default && $(KUSTOMIZE) edit set namespace $(NAMESPACE)
	@$(MAKE) deploy IMG=$(DEV_IMG):$(DEV_TAG)

.PHONY: _operator-wait-ready
_operator-wait-ready:
	@echo "Waiting for operator pods to be ready..."
	@ATTEMPTS=0; \
	while [ $$ATTEMPTS -lt 30 ]; do \
		READY=$$($(KUBECTL) get deployment $(DEPLOYMENT_NAME) -n $(NAMESPACE) \
			-o jsonpath='{.status.readyReplicas}' 2>/dev/null); \
		DESIRED=$$($(KUBECTL) get deployment $(DEPLOYMENT_NAME) -n $(NAMESPACE) \
			-o jsonpath='{.status.replicas}' 2>/dev/null); \
		if [ -n "$$READY" ] && [ -n "$$DESIRED" ] && [ "$$READY" = "$$DESIRED" ] && [ "$$READY" -gt 0 ]; then \
			echo "All pods ready ($$READY/$$DESIRED)."; \
			break; \
		fi; \
		echo "Pods not ready ($$READY/$$DESIRED). Waiting..."; \
		ATTEMPTS=$$((ATTEMPTS + 1)); \
		sleep 10; \
	done; \
	if [ $$ATTEMPTS -ge 30 ]; then \
		echo "ERROR: Timed out waiting for operator pods to be ready (5 minutes)." >&2; \
		exit 1; \
	fi
	@$(KUBECTL) config set-context --current --namespace=$(NAMESPACE)

.PHONY: _operator-post-deploy
_operator-post-deploy:
	@# Apply dev custom configs (secrets, configmaps, etc.) from DEV_CUSTOM_CONFIG
	@$(MAKE) _apply-custom-config
	@if [ "$(CREATE_CR)" = "true" ] && [ -f "$(DEV_CR)" ]; then \
		echo "Applying dev CR: $(DEV_CR)"; \
		$(KUBECTL) apply -n $(NAMESPACE) -f $(DEV_CR); \
	fi

#@ Teardown

.PHONY: _teardown-restores
_teardown-restores:
	@for kind in $(TEARDOWN_RESTORE_KINDS); do \
		echo "Deleting $$kind resources..."; \
		$(KUBECTL) delete $$kind -n $(NAMESPACE) --all --wait=true --ignore-not-found=true || true; \
	done

.PHONY: _teardown-backups
_teardown-backups:
	@for kind in $(TEARDOWN_BACKUP_KINDS); do \
		echo "Deleting $$kind resources..."; \
		$(KUBECTL) delete $$kind -n $(NAMESPACE) --all --wait=true --ignore-not-found=true || true; \
	done

.PHONY: _teardown-operands
_teardown-operands:
	@for kind in $(TEARDOWN_CR_KINDS); do \
		echo "Deleting $$kind resources..."; \
		$(KUBECTL) delete $$kind -n $(NAMESPACE) --all --wait=true --ignore-not-found=true || true; \
	done

.PHONY: _teardown-pvcs
_teardown-pvcs:
	@if [ "$(DELETE_PVCS)" = "true" ]; then \
		echo "Deleting PVCs..."; \
		$(KUBECTL) delete pvc -n $(NAMESPACE) --all --ignore-not-found=true; \
	else \
		echo "Keeping PVCs (DELETE_PVCS=false)"; \
	fi

.PHONY: _teardown-secrets
_teardown-secrets:
	@if [ "$(DELETE_SECRETS)" = "true" ]; then \
		echo "Deleting secrets..."; \
		$(KUBECTL) delete secrets -n $(NAMESPACE) --all --ignore-not-found=true; \
	else \
		echo "Keeping secrets (DELETE_SECRETS=false)"; \
	fi

.PHONY: _teardown-olm
_teardown-olm:
	@for sub in $(OLM_SUBSCRIPTIONS); do \
		echo "Deleting subscription $$sub..."; \
		$(KUBECTL) delete subscription $$sub -n $(NAMESPACE) --ignore-not-found=true || true; \
	done
	@CSV=$$($(KUBECTL) get csv -n $(NAMESPACE) --no-headers -o custom-columns=":metadata.name" 2>/dev/null | grep aap-operator || true); \
	if [ -n "$$CSV" ]; then \
		echo "Deleting CSV: $$CSV"; \
		$(KUBECTL) delete csv $$CSV -n $(NAMESPACE) --ignore-not-found=true; \
	fi

.PHONY: _teardown-namespace
_teardown-namespace:
	@if [ "$(KEEP_NAMESPACE)" != "true" ]; then \
		echo "Deleting namespace $(NAMESPACE)..."; \
		$(KUBECTL) delete namespace $(NAMESPACE) --ignore-not-found=true; \
	else \
		echo "Keeping namespace $(NAMESPACE) (KEEP_NAMESPACE=true)"; \
	fi

##@ Registry

.PHONY: registry-login
registry-login: ## Login to container registries
	@for registry in $(REGISTRIES); do \
		echo "Logging into $$registry..."; \
		$(_CONTAINER_CMD) login $$registry; \
	done

##@ Namespace

.PHONY: ns-wait
ns-wait: ## Wait for namespace to finish terminating
	@if $(KUBECTL) get namespace $(NAMESPACE) 2>/dev/null | grep -q 'Terminating'; then \
		echo "Namespace $(NAMESPACE) is terminating. Waiting..."; \
		while $(KUBECTL) get namespace $(NAMESPACE) 2>/dev/null | grep -q 'Terminating'; do \
			sleep 5; \
		done; \
		echo "Namespace $(NAMESPACE) terminated."; \
	fi

.PHONY: ns-create
ns-create: ## Create namespace if it does not exist
	@if ! $(KUBECTL) get namespace $(NAMESPACE) --no-headers 2>/dev/null | grep -q .; then \
		echo "Creating namespace $(NAMESPACE)"; \
		$(KUBECTL) create namespace $(NAMESPACE); \
	else \
		echo "Namespace $(NAMESPACE) already exists"; \
	fi

.PHONY: ns-security
ns-security: ## Configure namespace security for OLM bundle unpacking
	@if ! oc get scc anyuid >/dev/null 2>&1; then \
		echo "No SCC support detected (vanilla Kubernetes), applying pod security labels..."; \
		$(KUBECTL) label namespace "$(NAMESPACE)" \
			pod-security.kubernetes.io/enforce=privileged \
			pod-security.kubernetes.io/audit=privileged \
			pod-security.kubernetes.io/warn=privileged --overwrite; \
	elif $(KUBECTL) get namespace openshift-apiserver >/dev/null 2>&1; then \
		echo "Full OpenShift detected — skipping SCC grants (OLM handles bundle unpacking)"; \
	else \
		echo "MicroShift detected — granting SCCs for bundle unpack pods in $(NAMESPACE)..."; \
		oc adm policy add-scc-to-user privileged -z default -n "$(NAMESPACE)" 2>/dev/null || true; \
		oc adm policy add-scc-to-user anyuid -z default -n "$(NAMESPACE)" 2>/dev/null || true; \
	fi

##@ Secrets

.PHONY: pull-secret
pull-secret: ## Apply pull secret from file or create from auth config
	@if [ "$(CREATE_PULL_SECRET)" != "true" ]; then \
		echo "Pull secret creation disabled (CREATE_PULL_SECRET=false)"; \
		exit 0; \
	fi; \
	if [ -f "$(PULL_SECRET_FILE)" ]; then \
		echo "Applying pull secret from $(PULL_SECRET_FILE)"; \
		$(KUBECTL) apply -n $(NAMESPACE) -f $(PULL_SECRET_FILE); \
	elif [ -n "$(REGISTRY_AUTH_CONFIG)" ] && [ -f "$(REGISTRY_AUTH_CONFIG)" ]; then \
		if ! $(KUBECTL) get secret redhat-operators-pull-secret -n $(NAMESPACE) 2>/dev/null | grep -q .; then \
			echo "Creating pull secret from $(REGISTRY_AUTH_CONFIG)"; \
			$(KUBECTL) create secret generic redhat-operators-pull-secret \
				--from-file=.dockerconfigjson="$(REGISTRY_AUTH_CONFIG)" \
				--type=kubernetes.io/dockerconfigjson \
				-n $(NAMESPACE); \
		else \
			echo "Pull secret already exists"; \
		fi; \
	else \
		echo "No pull secret file or registry auth config found, skipping"; \
		exit 0; \
	fi; \
	echo "Linking pull secret to default service account..."; \
	$(KUBECTL) patch serviceaccount default -n $(NAMESPACE) \
		-p '{"imagePullSecrets": [{"name": "redhat-operators-pull-secret"}]}' 2>/dev/null \
		&& echo "Pull secret linked to default SA" \
		|| echo "Warning: could not link pull secret to default SA"

##@ Build

.PHONY: podman-build
podman-build: ## Build image with podman
	$(_CONTAINER_CMD) build $(BUILD_ARGS) -t ${IMG} .

.PHONY: podman-push
podman-push: ## Push image with podman
	$(_CONTAINER_CMD) push ${IMG}

.PHONY: podman-buildx
podman-buildx: ## Build multi-arch image with podman
	$(_CONTAINER_CMD) build $(BUILD_ARGS) --platform=$(PLATFORMS) --manifest ${IMG} -f Dockerfile .

.PHONY: podman-buildx-push
podman-buildx-push: podman-buildx ## Build and push multi-arch image with podman
	$(_CONTAINER_CMD) manifest push --all ${IMG}

.PHONY: dev-build
dev-build: ## Build dev image (auto-detects arch of connected cluster, cross-compiles if needed)
	@HOST_ARCH=$$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/'); \
	CLUSTER_ARCH=$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.nodeInfo.architecture}' 2>/dev/null); \
	if [ -z "$$CLUSTER_ARCH" ]; then \
		echo "WARNING: Could not detect cluster architecture. Is the cluster reachable?"; \
		echo "  Falling back to host architecture ($$HOST_ARCH)"; \
		CLUSTER_ARCH="$$HOST_ARCH"; \
	fi; \
	echo "Building $(DEV_IMG):$(DEV_TAG) with $(CONTAINER_TOOL)..."; \
	echo "  Host arch:    $$HOST_ARCH"; \
	echo "  Cluster arch: $$CLUSTER_ARCH"; \
	if [ "$(MULTI_ARCH)" = "true" ]; then \
		echo "  Build mode:   multi-arch ($(PLATFORMS))"; \
		$(MAKE) $(CONTAINER_TOOL)-buildx IMG=$(DEV_IMG):$(DEV_TAG) PLATFORMS=$(PLATFORMS); \
	elif [ -n "$(PLATFORM)" ]; then \
		echo "  Build mode:   cross-arch ($(PLATFORM))"; \
		$(MAKE) $(CONTAINER_TOOL)-buildx IMG=$(DEV_IMG):$(DEV_TAG) PLATFORMS=$(PLATFORM); \
	elif [ "$$HOST_ARCH" != "$$CLUSTER_ARCH" ]; then \
		echo "  Build mode:   cross-arch (linux/$$CLUSTER_ARCH)"; \
		$(MAKE) $(CONTAINER_TOOL)-buildx-push IMG=$(DEV_IMG):$(DEV_TAG) PLATFORMS=linux/$$CLUSTER_ARCH; \
	else \
		echo "  Build mode:   local ($$HOST_ARCH)"; \
		$(MAKE) $(CONTAINER_TOOL)-build IMG=$(DEV_IMG):$(DEV_TAG); \
		if [ "$(IMAGE_PULL_POLICY)" != "Never" ]; then \
			echo "WARNING: Local build without push. Set IMAGE_PULL_POLICY=Never or the kubelet"; \
			echo "  will attempt to pull $(DEV_IMG):$(DEV_TAG) from a registry and fail."; \
		fi; \
	fi

##@ Deployment Helpers

.PHONY: patch-pull-policy
patch-pull-policy: ## Patch imagePullPolicy in manager config (default: Always, override with IMAGE_PULL_POLICY)
	@_POLICY="$(if $(IMAGE_PULL_POLICY),$(IMAGE_PULL_POLICY),Always)"; \
	for file in config/manager/manager.yaml; do \
		if [ -f "$$file" ] && grep -q 'imagePullPolicy: IfNotPresent' "$$file"; then \
			echo "Patching imagePullPolicy to $$_POLICY in $$file"; \
			$(_SED_I) "s|imagePullPolicy: IfNotPresent|imagePullPolicy: $$_POLICY|g" "$$file"; \
		fi; \
	done

.PHONY: pre-deploy-cleanup
pre-deploy-cleanup: ## Delete existing operator deployment (safe)
	@if [ -n "$(DEPLOYMENT_NAME)" ]; then \
		echo "Cleaning up deployment $(DEPLOYMENT_NAME)..."; \
		$(KUBECTL) delete deployment $(DEPLOYMENT_NAME) \
			-n $(NAMESPACE) --ignore-not-found=true; \
	fi

.PHONY: _apply-custom-config
_apply-custom-config: ## Apply custom configs (secrets, configmaps, etc.)
	@for f in $(DEV_CUSTOM_CONFIG); do \
		if [ -f "$$f" ]; then \
			echo "Applying custom config: $$f"; \
			$(KUBECTL) apply -n $(NAMESPACE) -f $$f; \
		else \
			echo "WARNING: Custom config not found: $$f"; \
		fi; \
	done

#@ Validation

.PHONY: _require-img
_require-img:
	@if [ -z "$(DEV_IMG)" ]; then \
		echo "Error: Set QUAY_USER or DEV_IMG."; \
		echo "  export QUAY_USER=<your-quay-username>"; \
		echo "  or: DEV_IMG=registry.example.com/my-operator make up"; \
		exit 1; \
	fi
	@if echo "$(DEV_IMG)" | grep -q '^registry\.redhat\.io'; then \
		echo "Error: Cannot push to registry.redhat.io (production registry)."; \
		echo "  Set QUAY_USER or DEV_IMG to use a personal registry."; \
		exit 1; \
	fi
	@if echo "$(DEV_IMG)" | grep -q '^quay\.io/'; then \
		if [ -z "$(QUAY_USER)" ]; then \
			echo "Error: Cannot push to quay.io without QUAY_USER."; \
			echo "  export QUAY_USER=<your-quay-username>"; \
			echo "  or: DEV_IMG=<your-registry>/<image> make up"; \
			exit 1; \
		fi; \
		if ! echo "$(DEV_IMG)" | grep -q '^quay\.io/$(QUAY_USER)/'; then \
			echo "Error: DEV_IMG ($(DEV_IMG)) does not match QUAY_USER ($(QUAY_USER))."; \
			echo "  Expected: quay.io/$(QUAY_USER)/<image>"; \
			echo "  Either fix QUAY_USER or set DEV_IMG explicitly."; \
			exit 1; \
		fi; \
	fi

.PHONY: _require-namespace
_require-namespace:
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "Error: NAMESPACE is required. Set it in operator.mk or run: export NAMESPACE=<namespace>"; \
		exit 1; \
	fi

##@ Linting

LINT_PATHS ?= roles/ playbooks/ config/samples/ config/manager/

.PHONY: lint
lint: ## Run ansible-lint and check no_log usage
	@echo "Checking if ansible-lint is installed..."
	@which ansible-lint > /dev/null || (echo "ansible-lint not found, installing..." && pip install --user ansible-lint)
	@echo "Running ansible-lint..."
	@ansible-lint $(LINT_PATHS)
	@if [ -d "roles/" ]; then \
		echo "Checking for no_log instances that need to use the variable..."; \
		if grep -nr ' no_log:' roles | grep -qv '"{{ no_log }}"'; then \
			echo 'Please update the following no_log statement(s) with the "{{ no_log }}" value'; \
			grep -nr ' no_log:' roles | grep -v '"{{ no_log }}"'; \
			exit 1; \
		fi; \
	fi
