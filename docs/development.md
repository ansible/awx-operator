# Development Guide

There are development scripts and yaml examples in the [`dev/`](../dev) directory that, along with the up.sh and down.sh scripts in the root of the repo, can be used to build, deploy and test changes made to the awx-operator.


## Prerequisites

You will need to have the following tools installed:

* [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* [podman](https://podman.io/docs/installation) or [docker](https://docs.docker.com/get-docker/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [oc](https://docs.openshift.com/container-platform/4.11/cli_reference/openshift_cli/getting-started-cli.html) (if using Openshift)

You will also need to have a container registry account. This guide uses quay.io, but any container registry will work. You will need to create a robot account and login at the CLI with `podman login` or `docker login`.

## Quay.io Setup for Development

Before using the development scripts, you'll need to set up a Quay.io repository and pull secret:

### 1. Create a Private Quay.io Repository
- Go to [quay.io](https://quay.io) and create a private repository named `awx-operator` under your username
- The repository URL should be `quay.io/username/awx-operator`

### 2. Create a Bot Account
- In your Quay.io repository, go to Settings → Robot Accounts
- Create a new robot account with write permissions to your repository
- Click on the robot account name to view its credentials

### 3. Generate Kubernetes Pull Secret
- In the robot account details, click "Kubernetes Secret"
- Copy the generated YAML content from the pop-up

### 4. Create Local Pull Secret File
- Create a file at `hacking/pull-secret.yml` in your awx-operator checkout
- Paste the Kubernetes secret YAML content into this file
- **Important**: Change the `name` field in the secret from the default to `redhat-operators-pull-secret`
- The `hacking/` directory is in `.gitignore`, so this file won't be committed to git

Example `hacking/pull-secret.yml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: redhat-operators-pull-secret  # Change this name
  namespace: awx
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-credentials>
```

## Build and Deploy


If you clone the repo, and make sure you are logged in at the CLI with oc and your cluster, you can run:

```
export QUAY_USER=username
export NAMESPACE=awx
export TAG=test
./up.sh
```

You can add those variables to your .bashrc file so that you can just run `./up.sh` in the future.

> Note: the first time you run this, it will create quay.io repos on your fork. If you followed the Quay.io setup steps above and created the `hacking/pull-secret.yml` file, the script will automatically handle the pull secret. Otherwise, you will need to either make those repos public, or create a global pull secret on your cluster.

To get the URL, if on **Openshift**, run:

```
$ oc get route
```

On **k8s with ingress**, run:

```
$ kubectl get ing
```

On **k8s with nodeport**, run:

```
$ kubectl get svc
```

The URL is then `http://<Node-IP>:<NodePort>`

> Note: NodePort will only work if you expose that port on your underlying k8s node, or are accessing it from localhost.

By default, the usename and password will be admin and password if using the `up.sh` script because it pre-creates a custom admin password k8s secret and specifies it on the AWX custom resource spec. Without that, a password would have been generated and stored in a k8s secret named <deployment-name>-admin-password.

## Clean up


Same thing for cleanup, just run ./down.sh and it will clean up your namespace on that cluster


```
./down.sh
```

## Running CI tests locally

More tests coming soon...
