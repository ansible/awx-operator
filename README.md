# Ansible Tower/AWX Operator

An [Ansible AWX](https://github.com/ansible/awx) operator for Kubernetes built with [Operator SDK](https://github.com/operator-framework/operator-sdk) and Ansible.

Also configurable to be able to run [Tower](https://ansible.com/products/tower)

## Purpose

There are already official OpenShift/Kubernetes installers available for both AWX and Ansible Tower:

  - [AWX on Kubernetes](https://github.com/ansible/awx/blob/devel/INSTALL.md#kubernetes)
  - [Ansible Tower on Kubernetes](https://docs.ansible.com/ansible-tower/latest/html/administration/openshift_configuration.html)

This operator is meant to provide a more Kubernetes-native installation method for Ansible Tower or AWX via an AWX Custom Resource Definition (CRD).

Note that the operator is not supported by Red Hat, and is in alpha status. Long-term, this operator will become the supported method of installing on Kubernetes and Openshift, and will be listed on OperatorHub.io. For now, use it at your own risk!

## Usage

This Kubernetes Operator is meant to be deployed in your Kubernetes cluster(s) and can manage one or more Tower or AWX instances in any namespace.

First you need to deploy AWX Operator into your cluster:

```bash
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/devel/deploy/awx-operator.yaml
```

Then you can create instances of AWX, for example:

  1. Make sure the namespace you're deploying into already exists (e.g. `kubectl create namespace ansible-awx`).
  2. Create a file named `my-awx.yml` with the following contents:

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: ansible-awx
spec:
  deployment_type: awx
  tower_admin_user: test
  tower_admin_email: test@example.com
  tower_admin_password: changeme
  tower_broadcast_websocket_secret: changeme
```

  3. Use `kubectl` to create the mcrouter instance in your cluster:

```bash
kubectl apply -f my-awx.yml
```

After a few minutes, your new AWX instance will be accessible at `http://awx.mycompany.com/` (assuming your cluster has an Ingress controller configured). Log in using the `tower_admin_` credentials configured in the `spec`.


### Ingress Types

Depending on the cluster that you're running on, you may wish to use an `Ingress` to access your tower or you may wish to use a `Route` to access your awx. To toggle between these two options, you can add the following to your Tower custom resource:

```yaml
---
spec:
  ...
  tower_ingress_type: Route
```

OR

```yaml
---
spec:
  ...
  tower_ingress_type: Ingress
  tower_hostname: awx.mycompany.com
```

By default, no ingress/route is deployed as the default is set to `none`.

### Privileged Tasks

Depending on the type of tasks that you'll be running, you may find that you need the tower task pod to run as `privileged`. This can open yourself up to a variety of security concerns, so you should be aware (and verify that you have the privileges) to do this if necessary. In order to toggle this feature, you can add the following to your Tower custom resource:

```yaml
---
spec:
  ...
  tower_task_privileged: true
```

If you are attempting to do this on an OpenShift cluster, you will need to grant the `awx` ServiceAccount the `privileged` SCC, which can be done with:

```bash
oc adm policy add-scc-to-user privileged -z awx
```

Again, this is the most relaxed SCC that is provided by OpenShift, so be sure to familiarize yourself with the security concerns that accompany this action.

### Connecting to an external Postgres Service

When the Operator installs the AWX services and generates a Postgres deployment it will lay down a config file to enable AWX to connect to that service. To use an external database you just need to create a `Secret` that the AWX deployment will use instead and then set a property in the CR:

```yaml
---
spec:
  ...
  external_database: true
```

The secret should have the name: *crname*-postgres-configuration and
should look like:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: <crname>-postgres-configuration
  namespace: <target namespace>
stringData:
  address: <external ip or url resolvable by the cluster>
  port: <external port, this usually defaults to 5432>
  database: <desired database name>
  username: <username to connect as>
  password: <password to connect with>
type: Opaque
```

### Persistent storage for Postgres

If you need to use a specific storage class for Postgres' storage, specify `tower_postgres_storage_class` in your Tower spec:

```yaml
---
spec:
  ...
  tower_postgres_storage_class: fast-ssd
```

If it's not specified, Postgres will store it's data on a volume using the default storage class for your cluster.

## Development

### Testing

This Operator includes a [Molecule](https://molecule.readthedocs.io/en/stable/)-based test environment, which can be executed standalone in Docker (e.g. in CI or in a single Docker container anywhere), or inside any kind of Kubernetes cluster (e.g. Minikube).

You need to make sure you have Molecule installed before running the following commands. You can install Molecule with:

```bash
pip install 'molecule[docker]'
```

Running `molecule test` sets up a clean environment, builds the operator, runs all configured tests on an example operator instance, then tears down the environment (at least in the case of Docker).

If you want to actively develop the operator, use `molecule converge`, which does everything but tear down the environment at the end.

#### Testing in Docker (standalone)

```bash
molecule test -s test-local
```

This environment is meant for headless testing (e.g. in a CI environment, or when making smaller changes which don't need to be verified through a web interface). It is difficult to test things like Tower's web UI or to connect other applications on your local machine to the services running inside the cluster, since it is inside a Docker container with no static IP address.

#### Testing in Minikube

```bash
minikube start --memory 8g --cpus 4
minikube addons enable ingress
molecule test -s test-minikube
```

[Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) is a more full-featured test environment running inside a full VM on your computer, with an assigned IP address. This makes it easier to test things like NodePort services and Ingress from outside the Kubernetes cluster (e.g. in a browser on your computer).

Once the operator is deployed, you can visit the Tower UI in your browser by following these steps:

  1. Make sure you have an entry like `IP_ADDRESS  example-tower.test` in your `/etc/hosts` file. (Get the IP address with `minikube ip`.)
  2. Visit `http://example-tower.test/` in your browser. (Default admin login is `test`/`changeme`.)

### Release Process

There are a few moving parts to this project:

  1. The Docker image which powers AWX Operator.
  2. The `awx-operator.yaml` Kubernetes manifest file which initially deploys the Operator into a cluster.

Each of these must be appropriately built in preparation for a new tag:

#### Build a new release of the Operator for Docker Hub

Run the following command inside this directory:

```bash
operator-sdk build ansible/awx-operator:0.4.0
```

Then push the generated image to Docker Hub:

```bash
docker push ansible/awx-operator:0.4.0
```

#### Build a new version of the `awx-operator.yaml` file

Update the awx-operator version in two places:

  1. `deploy/awx-operator.yaml`: in the `ansible` and `operator` container definitions in the `awx-operator` Deployment.
  2. `build/chain-operator-files.yml`: the `operator_image` variable.

Once the versions are updated, run the playbook in the `build/` directory:

```bash
ansible-playbook chain-operator-files.yml
```

After it is built, test it on a local cluster:

```bash
minikube start --memory 6g --cpus 4
minikube addons enable ingress
kubectl apply -f deploy/awx-operator.yaml
kubectl create namespace example-awx
kubectl apply -f deploy/crds/tower_v1beta1_tower_cr_awx.yaml
# <test everything>
minikube delete
```


If everything works, commit the updated version, then tag a new repository release with the same tag as the Docker image pushed earlier.

## Author

This operator was originally built in 2019 by [Jeff Geerling](https://www.jeffgeerling.com) and is now maintained by the Ansible Team
