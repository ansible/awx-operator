# Development Guide

There are development yaml examples in the [`dev/`](https://github.com/ansible/awx-operator/tree/devel/dev) directory and Makefile targets that can be used to build, deploy and test changes made to the awx-operator.

Run `make help` to see all available targets and options.


## Prerequisites

You will need to have the following tools installed:

* [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* [podman](https://podman.io/docs/installation) or [docker](https://docs.docker.com/get-docker/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [oc](https://docs.openshift.com/container-platform/4.11/cli_reference/openshift_cli/getting-started-cli.html) (if using OpenShift)

You will also need a container registry account. This guide uses [quay.io](https://quay.io), but any container registry will work.


## Registry Setup

### Create a Quay.io Repository

1. Go to [quay.io](https://quay.io) and create a repository named `awx-operator` under your username.
2. Login at the CLI:
```sh
podman login quay.io
```

### Pull Secret (optional)

If your repository is private, you'll need to configure a pull secret so the cluster can pull your operator image:

1. In your Quay.io repository, go to Settings → Robot Accounts.
2. Create a robot account with write permissions.
3. Click the robot account name, then click "Kubernetes Secret" and copy the YAML.
4. Save it to `hacking/pull-secret.yml` in your checkout (this path is in `.gitignore`).
5. Change the `name` field to `redhat-operators-pull-secret`.

Example:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: redhat-operators-pull-secret
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-credentials>
```

If a pull secret file is found at `hacking/pull-secret.yml` (or the path set by `PULL_SECRET_FILE`), `make up` will apply it automatically. Otherwise, you can make your quay.io repos public or create a global pull secret on your cluster.


## Build and Deploy

Make sure you are logged into your cluster (`oc login` or `kubectl` configured), then run:

```sh
QUAY_USER=username make up
```

This will:
1. Login to container registries
2. Create the target namespace
3. Build the operator image and push it to your registry
4. Deploy the operator via kustomize
5. Apply dev secrets and create a dev AWX instance

### Customization Options

| Variable | Default | Description |
|----------|---------|-------------|
| `QUAY_USER` | _(required)_ | Your quay.io username |
| `NAMESPACE` | `awx` | Target namespace |
| `DEV_TAG` | `dev` | Image tag for dev builds |
| `CONTAINER_TOOL` | `podman` | Container engine (`podman` or `docker`) |
| `PLATFORM` | _(auto-detected)_ | Target platform (e.g., `linux/amd64`) |
| `MULTI_ARCH` | `false` | Build multi-arch image (`linux/arm64,linux/amd64`) |
| `DEV_IMG` | `quay.io/<QUAY_USER>/awx-operator` | Override full image path (skips QUAY_USER) |
| `BUILD_IMAGE` | `true` | Set to `false` to skip image build (use existing image) |
| `CREATE_CR` | `true` | Set to `false` to skip creating the dev AWX instance |
| `CREATE_SECRETS` | `true` | Set to `false` to skip creating dev secrets |
| `IMAGE_PULL_POLICY` | `Always` | Set to `Never` for local builds without push |
| `BUILD_ARGS` | _(empty)_ | Extra args passed to container build (e.g., `--no-cache`) |
| `DEV_CR` | `dev/awx-cr/awx-openshift-cr.yml` | Path to the dev CR to apply |
| `PULL_SECRET_FILE` | `dev/pull-secret.yml` | Path to pull secret YAML |
| `PODMAN_CONNECTION` | _(empty)_ | Remote podman connection name |

Examples:

```bash
# Use a specific namespace and tag
QUAY_USER=username NAMESPACE=awx DEV_TAG=mytag make up

# Use docker instead of podman
CONTAINER_TOOL=docker QUAY_USER=username make up

# Build for a specific platform (e.g., when on ARM building for x86)
PLATFORM=linux/amd64 QUAY_USER=username make up

# Deploy without building (use an existing image)
BUILD_IMAGE=false DEV_IMG=quay.io/myuser/awx-operator DEV_TAG=latest make up

# Build without pushing (local cluster like kind/minikube)
IMAGE_PULL_POLICY=Never QUAY_USER=username make up
```

### Accessing the Deployment

On **OpenShift**:
```sh
oc get route
```

On **k8s with ingress**:
```sh
kubectl get ing
```

On **k8s with nodeport**:
```sh
kubectl get svc
```
The URL is then `http://<Node-IP>:<NodePort>`.

> **Note**: NodePort will only work if you expose that port on your underlying k8s node, or are accessing it from localhost.

### Default Credentials

The dev CR pre-creates an admin password secret. Default credentials are:
- **Username**: `admin`
- **Password**: `password`

Without the dev CR, a password would be generated and stored in a secret named `<deployment-name>-admin-password`.


## Clean up

To tear down your development deployment:

```sh
make down
```

### Teardown Options

| Variable | Default | Description |
|----------|---------|-------------|
| `KEEP_NAMESPACE` | `false` | Set to `true` to keep the namespace for reuse |
| `DELETE_PVCS` | `true` | Set to `false` to preserve PersistentVolumeClaims |
| `DELETE_SECRETS` | `true` | Set to `false` to preserve secrets |

Examples:

```bash
# Keep the namespace for faster redeploy
KEEP_NAMESPACE=true make down

# Keep PVCs (preserve database data between deploys)
DELETE_PVCS=false make down
```


## Testing

### Linting

Run linting checks (required for all PRs):

```sh
make lint
```

This runs `ansible-lint` on roles, playbooks, and config samples, and checks that `no_log` statements use the `{{ no_log }}` variable.

### Molecule Tests

The operator includes a [Molecule](https://ansible.readthedocs.io/projects/molecule/)-based test environment for integration testing. Molecule can run standalone in Docker or inside a Kubernetes cluster.

Install Molecule:

```sh
python -m pip install molecule-plugins[docker]
```

#### Testing in Kind (recommended)

[Kind](https://kind.sigs.k8s.io/docs/user/quick-start/) is the recommended way to test locally:

```sh
molecule test -s kind
```

#### Testing in Minikube

```sh
minikube start --memory 8g --cpus 4
minikube addons enable ingress
molecule test -s test-minikube
```

[Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) runs a full VM with an assigned IP address, making it easier to test NodePort services and Ingress from outside the cluster.

Once deployed, access the AWX UI:

1. Add `<minikube-ip>  example-awx.test` to your `/etc/hosts` file (get the IP with `minikube ip`).
2. Visit `http://example-awx.test/` (default login: `test`/`changeme`).

#### Active Development

Use `molecule converge` instead of `molecule test` to keep the environment running after tests complete — useful for iterating on changes.


## Bundle Generation

If you have the Operator Lifecycle Manager (OLM) installed, you can generate and deploy an operator bundle:

```bash
# Generate bundle manifests and validate
make bundle

# Build and push the bundle image
make bundle-build bundle-push

# Build and push a catalog image
make catalog-build catalog-push
```

After pushing the catalog, create a `CatalogSource` in your cluster pointing to the catalog image. Once the CatalogSource is in a READY state, the operator will be available in OperatorHub.
