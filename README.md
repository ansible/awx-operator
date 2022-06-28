# AWX Operator

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Build Status](https://github.com/ansible/awx-operator/workflows/CI/badge.svg?event=push)](https://github.com/ansible/awx-operator/actions)
[![Code of Conduct](https://img.shields.io/badge/code%20of%20conduct-Ansible-yellow.svg)](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html) 
[![AWX Mailing List](https://img.shields.io/badge/mailing%20list-AWX-orange.svg)](https://groups.google.com/g/awx-project)
[![IRC Chat - #ansible-awx](https://img.shields.io/badge/IRC-%23ansible--awx-blueviolet.svg)](https://libera.chat)

An [Ansible AWX](https://github.com/ansible/awx) operator for Kubernetes built with [Operator SDK](https://github.com/operator-framework/operator-sdk) and Ansible.

# Table of Contents
<!-- Regenerate this table of contents using https://github.com/ekalinin/github-markdown-toc -->
<!-- gh-md-toc --insert README.md -->
<!--ts-->
* [AWX Operator](#awx-operator)
* [Table of Contents](#table-of-contents)
   * [Purpose](#purpose)
   * [Usage](#usage)
      * [Creating a minikube cluster for testing](#creating-a-minikube-cluster-for-testing)
      * [Basic Install](#basic-install)
      * [Helm Install on existing cluster](#helm-install-on-existing-cluster)
      * [Admin user account configuration](#admin-user-account-configuration)
      * [Network and TLS Configuration](#network-and-tls-configuration)
         * [Service Type](#service-type)
         * [Ingress Type](#ingress-type)
      * [Database Configuration](#database-configuration)
         * [External PostgreSQL Service](#external-postgresql-service)
         * [Migrating data from an old AWX instance](#migrating-data-from-an-old-awx-instance)
         * [Managed PostgreSQL Service](#managed-postgresql-service)
      * [Advanced Configuration](#advanced-configuration)
         * [Deploying a specific version of AWX](#deploying-a-specific-version-of-awx)
         * [Redis container capabilities](#redis-container-capabilities)
         * [Privileged Tasks](#privileged-tasks)
         * [Containers Resource Requirements](#containers-resource-requirements)
         * [Priority Classes](#priority-classes)
         * [Assigning AWX pods to specific nodes](#assigning-awx-pods-to-specific-nodes)
         * [Trusting a Custom Certificate Authority](#trusting-a-custom-certificate-authority)
         * [Enabling LDAP Integration at AWX bootstrap](#enabling-ldap-integration-at-awx-bootstrap)
         * [Persisting Projects Directory](#persisting-projects-directory)
         * [Custom Volume and Volume Mount Options](#custom-volume-and-volume-mount-options)
         * [Default execution environments from private registries](#default-execution-environments-from-private-registries)
            * [Control plane ee from private registry](#control-plane-ee-from-private-registry)
         * [Exporting Environment Variables to Containers](#exporting-environment-variables-to-containers)
         * [CSRF Cookie Secure Setting](#csrf-cookie-secure-setting)
         * [Session Cookie Secure Setting](#session-cookie-secure-setting)
         * [Extra Settings](#extra-settings)
         * [Configure no_log](#no-log)
         * [Auto Upgrade](#auto-upgrade)
            * [Upgrade of instances without auto upgrade](#upgrade-of-instances-without-auto-upgrade)
         * [Service Account](#service-account)
      * [Uninstall](#uninstall)
      * [Upgrading](#upgrading)
         * [v0.14.0](#v0140)
            * [Cluster-scope to Namespace-scope considerations](#cluster-scope-to-namespace-scope-considerations)
            * [Project is now based on v1.x of the operator-sdk project](#project-is-now-based-on-v1x-of-the-operator-sdk-project)
            * [Steps to upgrade](#steps-to-upgrade)
   * [Contributing](#contributing)
   * [Release Process](#release-process)
   * [Author](#author)
   * [Code of Conduct](#code-of-conduct)
   * [Get Involved](#get-involved)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

<!--te-->

## Purpose

This operator is meant to provide a more Kubernetes-native installation method for AWX via an AWX Custom Resource Definition (CRD).

## Usage

This Kubernetes Operator is meant to be deployed in your Kubernetes cluster(s) and can manage one or more AWX instances in any namespace.

### Creating a minikube cluster for testing

If you do not have an existing cluster, the `awx-operator` can be deployed on a [Minikube](https://minikube.sigs.k8s.io/docs/) cluster for testing purposes. Due to different OS and hardware environments, please refer to the official Minikube documentation for further information.

```
$ minikube start --cpus=4 --memory=6g --addons=ingress
😄  minikube v1.23.2 on Fedora 34
✨  Using the docker driver based on existing profile
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🏃  Updating the running docker "minikube" container ...
🐳  Preparing Kubernetes v1.22.2 on Docker 20.10.8 ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
    ▪ Using image k8s.gcr.io/ingress-nginx/controller:v1.0.0-beta.3
    ▪ Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0
    ▪ Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0
🔎  Verifying ingress addon...
🌟  Enabled addons: storage-provisioner, default-storageclass, ingress
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

Once Minikube is deployed, check if the node(s) and `kube-apiserver` communication is working as expected.

```
$ minikube kubectl -- get nodes
NAME       STATUS   ROLES                  AGE    VERSION
minikube   Ready    control-plane,master   113s   v1.22.2

$ minikube kubectl -- get pods -A
NAMESPACE       NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx   ingress-nginx-admission-create--1-kk67h     0/1     Completed   0          2m1s
ingress-nginx   ingress-nginx-admission-patch--1-7mp2r      0/1     Completed   1          2m1s
ingress-nginx   ingress-nginx-controller-69bdbc4d57-bmwg8   1/1     Running     0          2m
kube-system     coredns-78fcd69978-q7nmx                    1/1     Running     0          2m
kube-system     etcd-minikube                               1/1     Running     0          2m12s
kube-system     kube-apiserver-minikube                     1/1     Running     0          2m16s
kube-system     kube-controller-manager-minikube            1/1     Running     0          2m12s
kube-system     kube-proxy-5mmnw                            1/1     Running     0          2m1s
kube-system     kube-scheduler-minikube                     1/1     Running     0          2m15s
kube-system     storage-provisioner                         1/1     Running     0          2m11s
```

It is not required for `kubectl` to be separately installed since it comes already wrapped inside minikube. As demonstrated above, simply prefix `minikube kubectl --` before kubectl command, i.e. `kubectl get nodes` would become `minikube kubectl -- get nodes`

Let's create an alias for easier usage:

```
$ alias kubectl="minikube kubectl --"
```

### Basic Install

Once you have a running Kubernetes cluster, you can deploy AWX Operator into your cluster using [Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/). Follow the instructions here to install the latest version of Kustomize: https://kubectl.docs.kubernetes.io/installation/kustomize/

First, create a file called `kustomization.yaml` with the following content:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases
  - github.com/ansible/awx-operator/config/default?ref=<tag>

# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator
    newTag: <tag>

# Specify a custom namespace in which to install AWX
namespace: awx
```

> **TIP:** If you need to change any of the default settings for the operator (such as resources.limits), you can add [patches](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/) at the bottom of your kustomization.yaml file.

Install the manifests by running this:

```
$ kustomize build . | kubectl apply -f -
namespace/awx created
customresourcedefinition.apiextensions.k8s.io/awxbackups.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxrestores.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxs.awx.ansible.com created
serviceaccount/awx-operator-controller-manager created
role.rbac.authorization.k8s.io/awx-operator-awx-manager-role created
role.rbac.authorization.k8s.io/awx-operator-leader-election-role created
clusterrole.rbac.authorization.k8s.io/awx-operator-metrics-reader created
clusterrole.rbac.authorization.k8s.io/awx-operator-proxy-role created
rolebinding.rbac.authorization.k8s.io/awx-operator-awx-manager-rolebinding created
rolebinding.rbac.authorization.k8s.io/awx-operator-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/awx-operator-proxy-rolebinding created
configmap/awx-operator-awx-manager-config created
service/awx-operator-controller-manager-metrics-service created
deployment.apps/awx-operator-controller-manager created
```

Wait a bit and you should have the `awx-operator` running:

```
$ kubectl get pods -n awx
NAME                                               READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-66ccd8f997-rhd4z   2/2     Running   0          11s
```

So we don't have to keep repeating `-n awx`, let's set the current namespace for `kubectl`:

```
$ kubectl config set-context --current --namespace=awx
```

Next, create a file named `awx-demo.yaml` in the same folder with the suggested content below. The `metadata.name` you provide will be the name of the resulting AWX deployment.

**Note:** If you deploy more than one AWX instance to the same namespace, be sure to use unique names.

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
  # default nodeport_port is 30080
  nodeport_port: <nodeport_port>
```

> It may make sense to create and specify your own secret key for your deployment so that if the k8s secret gets deleted, it can be re-created if needed.  If it is not provided, one will be auto-generated, but cannot be recovered if lost. Read more [here](#secret-key-configuration).

Make sure to add this new file to the list of "resources" in your `kustomization.yaml` file:

```yaml
...
resources:
  - github.com/ansible/awx-operator/config/default?ref=<tag>
  # Add this extra line:
  - awx-demo.yaml
...
```

Finally, run `kustomize` again to create the AWX instance in your cluster:

```
kustomize build . | kubectl apply -f -
```

After a few minutes, the new AWX instance will be deployed. You can look at the operator pod logs in order to know where the installation process is at:

```
$ kubectl logs -f deployments/awx-operator-controller-manager -c awx-manager
```

After a few seconds, you should see the operator begin to create new resources:

```
$ kubectl get pods -l "app.kubernetes.io/managed-by=awx-operator"
NAME                        READY   STATUS    RESTARTS   AGE
awx-demo-77d96f88d5-pnhr8   4/4     Running   0          3m24s
awx-demo-postgres-0         1/1     Running   0          3m34s

$ kubectl get svc -l "app.kubernetes.io/managed-by=awx-operator"
NAME                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
awx-demo-postgres   ClusterIP   None           <none>        5432/TCP       4m4s
awx-demo-service    NodePort    10.109.40.38   <none>        80:31006/TCP   3m56s
```

Once deployed, the AWX instance will be accessible by running:

```
$ minikube service awx-demo-service --url -n $NAMESPACE
```

By default, the admin user is `admin` and the password is available in the `<resourcename>-admin-password` secret. To retrieve the admin password, run:

```
$ kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode
yDL2Cx5Za94g9MvBP6B73nzVLlmfgPjR
```

You just completed the most basic install of an AWX instance via this operator. Congratulations!!!

For an example using the Nginx Controller in Minukube, don't miss our [demo video](https://asciinema.org/a/416946).


### Helm Install on existing cluster

For those that wish to use [Helm](https://helm.sh/) to install the awx-operator to an existing K8s cluster:

```bash
$ helm repo add awx-operator https://ansible.github.io/awx-operator/
"awx-operator" has been added to your repositories

$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "awx-operator" chart repository
Update Complete. ⎈Happy Helming!⎈

$ helm search repo awx-operator
NAME                            CHART VERSION   APP VERSION     DESCRIPTION
awx-operator/awx-operator       0.17.1          0.17.1          A Helm chart for the AWX Operator

$ helm install my-awx-operator awx-operator/awx-operator
NAME: my-awx-operator
LAST DEPLOYED: Thu Feb 17 22:09:05 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Helm Chart 0.17.1
```

### Admin user account configuration

There are three variables that are customizable for the admin user account creation.

| Name                  | Description                                  | Default          |
| --------------------- | -------------------------------------------- | ---------------- |
| admin_user            | Name of the admin user                       | admin            |
| admin_email           | Email of the admin user                      | test@example.com |
| admin_password_secret | Secret that contains the admin user password | Empty string     |


> :warning: **admin_password_secret must be a Kubernetes secret and not your text clear password**.

If `admin_password_secret` is not provided, the operator will look for a secret named `<resourcename>-admin-password` for the admin password. If it is not present, the operator will generate a password and create a Secret from it named `<resourcename>-admin-password`.

To retrieve the admin password, run `kubectl get secret <resourcename>-admin-password -o jsonpath="{.data.password}" | base64 --decode`

The secret that is expected to be passed should be formatted as follow:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: <resourcename>-admin-password
  namespace: <target namespace>
stringData:
  password: mysuperlongpassword
```


### Secret Key Configuration

This key is used to encrypt sensitive data in the database.

| Name              | Description                                           | Default          |
| ----------------- | ----------------------------------------------------- | ---------------- |
| secret_key_secret | Secret that contains the symmetric key for encryption | Generated     |


> :warning: **secret_key_secret must be a Kubernetes secret and not your text clear secret value**.

If `secret_key_secret` is not provided, the operator will look for a secret named `<resourcename>-secret-key` for the secret key. If it is not present, the operator will generate a password and create a Secret from it named `<resourcename>-secret-key`. It is important to not delete this secret as it will be needed for upgrades and if the pods get scaled down at any point. If you are using a GitOps flow, you will want to pass a secret key secret.

The secret should be formatted as follow:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: custom-awx-secret-key
  namespace: <target namespace>
stringData:
  secret_key: supersecuresecretkey
```

Then specify the secret name on the AWX spec:

```yaml
---
spec:
  ...
  secret_key_secret: custom-awx-secret-key
```

### Network and TLS Configuration

#### Service Type

If the `service_type` is not specified, the `ClusterIP` service will be used for your AWX Tower service.

The `service_type` supported options are: `ClusterIP`, `LoadBalancer` and `NodePort`.

The following variables are customizable for any `service_type`

| Name                | Description             | Default      |
| ------------------- | ----------------------- | ------------ |
| service_labels      | Add custom labels       | Empty string |
| service_annotations | Add service annotations | Empty string |

```yaml
---
spec:
  ...
  service_type: ClusterIP
  service_annotations: |
    environment: testing
  service_labels: |
    environment: testing
```

  * LoadBalancer

The following variables are customizable only when `service_type=LoadBalancer`

| Name                  | Description                              | Default |
| --------------------- | ---------------------------------------- | ------- |
| loadbalancer_protocol | Protocol to use for Loadbalancer ingress | http    |
| loadbalancer_port     | Port used for Loadbalancer ingress       | 80      |

```yaml
---
spec:
  ...
  service_type: LoadBalancer
  loadbalancer_protocol: https
  loadbalancer_port: 443
  service_annotations: |
    environment: testing
  service_labels: |
    environment: testing
```

When setting up a Load Balancer for HTTPS you will be required to set the `loadbalancer_port` to move the port away from `80`.

The HTTPS Load Balancer also uses SSL termination at the Load Balancer level and will offload traffic to AWX over HTTP.

  * NodePort

The following variables are customizable only when `service_type=NodePort`

| Name          | Description            | Default |
| ------------- | ---------------------- | ------- |
| nodeport_port | Port used for NodePort | 30080   |

```yaml
---
spec:
  ...
  service_type: NodePort
  nodeport_port: 30080
```
#### Ingress Type

By default, the AWX operator is not opinionated and won't force a specific ingress type on you. So, when the `ingress_type` is not specified, it will default to `none` and nothing ingress-wise will be created.

The `ingress_type` supported options are: `none`, `ingress` and `route`. To toggle between these options, you can add the following to your AWX CRD:

  * None

```yaml
---
spec:
  ...
  ingress_type: none
```

  * Generic Ingress Controller

The following variables are customizable when `ingress_type=ingress`. The `ingress` type creates an Ingress resource as [documented](https://kubernetes.io/docs/concepts/services-networking/ingress/) which can be shared with many other Ingress Controllers as [listed](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).

| Name                | Description                              | Default                     |
| ------------------- | ---------------------------------------- | --------------------------- |
| ingress_annotations | Ingress annotations                      | Empty string                |
| ingress_tls_secret  | Secret that contains the TLS information | Empty string                |
| hostname            | Define the FQDN                          | {{ meta.name }}.example.com |
| ingress_path        | Define the ingress path to the service   | /                           |
| ingress_path_type   | Define the type of the path (for LBs)    | Prefix                      |

```yaml
---
spec:
  ...
  ingress_type: ingress
  hostname: awx-demo.example.com
  ingress_annotations: |
    environment: testing
```

  * Route

The following variables are customizable when `ingress_type=route`

| Name                            | Description                                   | Default                                                 |
| ------------------------------- | --------------------------------------------- | ------------------------------------------------------- |
| route_host                      | Common name the route answers for             | `<instance-name>-<namespace>-<routerCanonicalHostname>` |
| route_tls_termination_mechanism | TLS Termination mechanism (Edge, Passthrough) | Edge                                                    |
| route_tls_secret                | Secret that contains the TLS information      | Empty string                                            |

```yaml
---
spec:
  ...
  ingress_type: route
  route_host: awx-demo.example.com
  route_tls_termination_mechanism: Passthrough
  route_tls_secret: custom-route-tls-secret-name
```

### Database Configuration

#### External PostgreSQL Service

To configure AWX to use an external database, the Custom Resource needs to know about the connection details. To do this, create a k8s secret with those connection details and specify the name of the secret as `postgres_configuration_secret` at the CR spec level.


The secret should be formatted as follows:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: <resourcename>-postgres-configuration
  namespace: <target namespace>
stringData:
  host: <external ip or url resolvable by the cluster>
  port: <external port, this usually defaults to 5432>
  database: <desired database name>
  username: <username to connect as>
  password: <password to connect with>
  sslmode: prefer
  type: unmanaged
type: Opaque
```

> Please ensure that the value for the variable `password` should _not_ contain single or double quotes (`'`, `"`) or backslashes (`\`) to avoid any issues during deployment, backup or restoration.

> It is possible to set a specific username, password, port, or database, but still have the database managed by the operator. In this case, when creating the postgres-configuration secret, the `type: managed` field should be added.

**Note**: The variable `sslmode` is valid for `external` databases only. The allowed values are: `prefer`, `disable`, `allow`, `require`, `verify-ca`, `verify-full`.

Once the secret is created, you can specify it on your spec:

```yaml
---
spec:
  ...
  postgres_configuration_secret: <name-of-your-secret>
```

#### Migrating data from an old AWX instance

For instructions on how to migrate from an older version of AWX, see [migration.md](./docs/migration.md).

#### Managed PostgreSQL Service

If you don't have access to an external PostgreSQL service, the AWX operator can deploy one for you along side the AWX instance itself.

The following variables are customizable for the managed PostgreSQL service

| Name                                          | Description                                   | Default                            |
| --------------------------------------------- | --------------------------------------------- | ---------------------------------- |
| postgres_image                                | Path of the image to pull                     | postgres:12                        |
| postgres_init_container_resource_requirements | Database init container resource requirements | requests: {cpu: 10m, memory: 64Mi} |
| postgres_resource_requirements                | PostgreSQL container resource requirements    | requests: {cpu: 10m, memory: 64Mi} |
| postgres_storage_requirements                 | PostgreSQL container storage requirements     | requests: {storage: 8Gi}           |
| postgres_storage_class                        | PostgreSQL PV storage class                   | Empty string                       |
| postgres_data_path                            | PostgreSQL data path                          | `/var/lib/postgresql/data/pgdata`  |
| postgres_priority_class                       | Priority class used for PostgreSQL pod        | Empty string                       |

Example of customization could be:

```yaml
---
spec:
  ...
  postgres_resource_requirements:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: 1
      memory: 4Gi
  postgres_storage_requirements:
    requests:
      storage: 8Gi
    limits:
      storage: 50Gi
  postgres_storage_class: fast-ssd
  postgres_extra_args:
    - '-c'
    - 'max_connections=1000'
```

**Note**: If `postgres_storage_class` is not defined, Postgres will store it's data on a volume using the default storage class for your cluster.

### Advanced Configuration

#### Deploying a specific version of AWX

There are a few variables that are customizable for awx the image management.

| Name                | Description               | Default                                 |
| ------------------- | ------------------------- | --------------------------------------  |
| image               | Path of the image to pull | quay.io/ansible/awx                     |
| image_version       | Image version to pull     | value of DEFAULT_AWX_VERSION or latest  |
| image_pull_policy   | The pull policy to adopt  | IfNotPresent                            |
| image_pull_secrets  | The pull secrets to use   | None                                    |
| ee_images           | A list of EEs to register | quay.io/ansible/awx-ee:latest           |
| redis_image         | Path of the image to pull | docker.io/redis                         |
| redis_image_version | Image version to pull     | latest                                  |

Example of customization could be:

```yaml
---
spec:
  ...
  image: myorg/my-custom-awx
  image_version: latest
  image_pull_policy: Always
  image_pull_secrets:
    - pull_secret_name
  ee_images:
    - name: my-custom-awx-ee
      image: myorg/my-custom-awx-ee
```

**Note**: The `image` and `image_version` are intended for local mirroring scenarios. Please note that using a version of AWX other than the one bundled with the `awx-operator` is **not** supported. For the default values, check the [main.yml](https://github.com/ansible/awx-operator/blob/devel/roles/installer/defaults/main.yml) file.

#### Redis container capabilities

Depending on your kubernetes cluster and settings you might need to grant some capabilities to the redis container so it can start. Set the `redis_capabilities` option so the capabilities are added in the deployment.

```yaml
---
spec:
  ...
  redis_capabilities:
    - CHOWN
    - SETUID
    - SETGID
```

#### Privileged Tasks

Depending on the type of tasks that you'll be running, you may find that you need the task pod to run as `privileged`. This can open yourself up to a variety of security concerns, so you should be aware (and verify that you have the privileges) to do this if necessary. In order to toggle this feature, you can add the following to your custom resource:

```yaml
---
spec:
  ...
  task_privileged: true
```

If you are attempting to do this on an OpenShift cluster, you will need to grant the `awx` ServiceAccount the `privileged` SCC, which can be done with:

```
$ oc adm policy add-scc-to-user privileged -z awx
```

Again, this is the most relaxed SCC that is provided by OpenShift, so be sure to familiarize yourself with the security concerns that accompany this action.


#### Containers Resource Requirements

The resource requirements for both, the task and the web containers are configurable - both the lower end (requests) and the upper end (limits).

| Name                       | Description                                      | Default                              |
| -------------------------- | ------------------------------------------------ | ------------------------------------ |
| web_resource_requirements  | Web container resource requirements              | requests: {cpu: 100m, memory: 128Mi} |
| task_resource_requirements | Task container resource requirements             | requests: {cpu: 100m, memory: 128Mi} |
| ee_resource_requirements   | EE control plane container resource requirements | requests: {cpu: 100m, memory: 128Mi} |

Example of customization could be:

```yaml
---
spec:
  ...
  web_resource_requirements:
    requests:
      cpu: 250m
      memory: 2Gi
    limits:
      cpu: 1000m
      memory: 4Gi
  task_resource_requirements:
    requests:
      cpu: 250m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 2Gi
  ee_resource_requirements:
    requests:
      cpu: 250m
      memory: 100Mi
    limits:
      cpu: 500m
      memory: 2Gi
```

#### Priority Classes

The AWX and Postgres pods can be assigned a custom PriorityClass to rank their importance compared to other pods in your cluster, which determines which pods get evicted first if resources are running low.
First, [create your PriorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass) if needed.
Then set the name of your priority class to the control plane and postgres pods as shown below.

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  ...
  control_plane_priority_class: awx-demo-high-priority
  postgres_priority_class: awx-demo-medium-priority
```

#### Assigning AWX pods to specific nodes

You can constrain the AWX pods created by the operator to run on a certain subset of nodes. `node_selector` and `postgres_selector` constrains
the AWX pods to run only on the nodes that match all the specified key/value pairs. `tolerations` and `postgres_tolerations` allow the AWX
pods to be scheduled onto nodes with matching taints.
The ability to specify topologySpreadConstraints is also allowed through `topology_spread_constraints`


| Name                        | Description                         | Default |
| --------------------------- | ----------------------------------- | ------- |
| postgres_image              | Path of the image to pull           | 12      |
| postgres_image_version      | Image version to pull               | 12      |
| node_selector               | AWX pods' nodeSelector              | ''      |
| topology_spread_constraints | AWX pods' topologySpreadConstraints | ''      |
| tolerations                 | AWX pods' tolerations               | ''      |
| annotations                 | AWX pods' annotations               | ''      |
| postgres_selector           | Postgres pods' nodeSelector         | ''      |
| postgres_tolerations        | Postgres pods' tolerations          | ''      |

Example of customization could be:

```yaml
---
spec:
  ...
  node_selector: |
    disktype: ssd
    kubernetes.io/arch: amd64
    kubernetes.io/os: linux
  topology_spread_constraints: |
    - maxSkew: 100
      topologyKey: "topology.kubernetes.io/zone"
      whenUnsatisfiable: "ScheduleAnyway"
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: "<resourcename>"
  tolerations: |
    - key: "dedicated"
      operator: "Equal"
      value: "AWX"
      effect: "NoSchedule"
  postgres_selector: |
    disktype: ssd
    kubernetes.io/arch: amd64
    kubernetes.io/os: linux
  postgres_tolerations: |
    - key: "dedicated"
      operator: "Equal"
      value: "AWX"
      effect: "NoSchedule"
```

#### Trusting a Custom Certificate Authority

In cases which you need to trust a custom Certificate Authority, there are few variables you can customize for the `awx-operator`.

Trusting a custom Certificate Authority allows the AWX to access network services configured with SSL certificates issued locally, such as cloning a project from from an internal Git server via HTTPS. It is common for these scenarios, experiencing the error [unable to verify the first certificate](https://github.com/ansible/awx-operator/issues/376).


| Name                             | Description                              | Default |
| -------------------------------- | ---------------------------------------- | --------|
| ldap_cacert_secret               | LDAP Certificate Authority secret name   |  ''     |
| ldap_password_secret             | LDAP BIND DN Password secret name        |  ''     |
| bundle_cacert_secret             | Certificate Authority secret name        |  ''     |
Please note the `awx-operator` will look for the data field `ldap-ca.crt` in the specified secret when using the `ldap_cacert_secret`, whereas the data field `bundle-ca.crt` is required for `bundle_cacert_secret` parameter.

Example of customization could be:

```yaml
---
spec:
  ...
  ldap_cacert_secret: <resourcename>-custom-certs
  ldap_password_secret: <resourcename>-ldap-password
  bundle_cacert_secret: <resourcename>-custom-certs
```

To create the secrets, you can use the commands below:

* Certificate Authority secret

```
# kubectl create secret generic <resourcename>-custom-certs \
    --from-file=ldap-ca.crt=<PATH/TO/YOUR/CA/PEM/FILE>  \
    --from-file=bundle-ca.crt=<PATH/TO/YOUR/CA/PEM/FILE>
```

* LDAP BIND DN Password secret

```
# kubectl create secret generic <resourcename>-ldap-password \
    --from-literal=ldap-password=<your_ldap_dn_password>
```

#### Enabling LDAP Integration at AWX bootstrap

A sample of extra settings can be found as below:

```yaml
    - setting: AUTH_LDAP_SERVER_URI
      value: >-
        "ldaps://ad01.abc.com:636 ldaps://ad02.abc.com:636"

    - setting: AUTH_LDAP_BIND_DN
      value: >-
        "CN=LDAP User,OU=Service Accounts,DC=abc,DC=com"

    - setting: AUTH_LDAP_USER_SEARCH
      value: 'LDAPSearch("DC=abc,DC=com",ldap.SCOPE_SUBTREE,"(sAMAccountName=%(user)s)",)'

    - setting: AUTH_LDAP_GROUP_SEARCH
      value: 'LDAPSearch("OU=Groups,DC=abc,DC=com",ldap.SCOPE_SUBTREE,"(objectClass=group)",)'

    - setting: AUTH_LDAP_USER_ATTR_MAP
      value: '{"first_name": "givenName","last_name": "sn","email": "mail"}'

    - setting: AUTH_LDAP_REQUIRE_GROUP
      value: >-
        "CN=operators,OU=Groups,DC=abc,DC=com"
    - setting: AUTH_LDAP_USER_FLAGS_BY_GROUP
      value: {
        "is_superuser": [
          "CN=admin,OU=Groups,DC=abc,DC=com"
        ]
      }


    - setting: AUTH_LDAP_ORGANIZATION_MAP
      value: {
        "abc": {
          "admins": "CN=admin,OU=Groups,DC=abc,DC=com",
          "remove_users": false,
          "remove_admins": false,
          "users": true
        }
      }

    - setting: AUTH_LDAP_TEAM_MAP
      value: {
        "admin": {
          "remove": true,
          "users": "CN=admin,OU=Groups,DC=abc,DC=com",
          "organization": "abc"
        }
      }
```

#### Persisting Projects Directory

In cases which you want to persist the `/var/lib/projects` directory, there are few variables that are customizable for the `awx-operator`.

| Name                         | Description                                                                                    | Default       |
| ---------------------------- | ---------------------------------------------------------------------------------------------- | ------------- |
| projects_persistence         | Whether or not the /var/lib/projects directory will be persistent                              | false         |
| projects_storage_class       | Define the PersistentVolume storage class                                                      | ''            |
| projects_storage_size        | Define the PersistentVolume size                                                               | 8Gi           |
| projects_storage_access_mode | Define the PersistentVolume access mode                                                        | ReadWriteMany |
| projects_existing_claim      | Define an existing PersistentVolumeClaim to use (cannot be combined with `projects_storage_*`) | ''            |

Example of customization when the `awx-operator` automatically handles the persistent volume could be:

```yaml
---
spec:
  ...
  projects_persistence: true
  projects_storage_class: rook-ceph
  projects_storage_size: 20Gi
```

#### Custom Volume and Volume Mount Options

In a scenario where custom volumes and volume mounts are required to either overwrite defaults or mount configuration files.

| Name                               | Description                                              | Default |
| ---------------------------------- | -------------------------------------------------------- | ------- |
| extra_volumes                      | Specify extra volumes to add to the application pod      | ''      |
| web_extra_volume_mounts            | Specify volume mounts to be added to Web container       | ''      |
| task_extra_volume_mounts           | Specify volume mounts to be added to Task container      | ''      |
| ee_extra_volume_mounts             | Specify volume mounts to be added to Execution container | ''      |
| init_container_extra_volume_mounts | Specify volume mounts to be added to Init container      | ''      |
| init_container_extra_commands      | Specify additional commands for Init container           | ''      |


> :warning: The `ee_extra_volume_mounts` and `extra_volumes` will only take effect to the globally available Execution Environments. For custom `ee`, please [customize the Pod spec](https://docs.ansible.com/ansible-tower/latest/html/administration/external_execution_envs.html#customize-the-pod-spec).

Example configuration for ConfigMap

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: <resourcename>-extra-config
  namespace: <target namespace>
data:
  ansible.cfg: |
     [defaults]
     remote_tmp = /tmp
     [ssh_connection]
     ssh_args = -C -o ControlMaster=auto -o ControlPersist=60s
  custom.py:  |
      INSIGHTS_URL_BASE = "example.org"
      AWX_CLEANUP_PATHS = True
```
Example spec file for volumes and volume mounts

```yaml
---
    spec:
    ...
      extra_volumes: |
        - name: ansible-cfg
          configMap:
            defaultMode: 420
            items:
              - key: ansible.cfg
                path: ansible.cfg
            name: <resourcename>-extra-config
        - name: custom-py
          configMap:
            defaultMode: 420
            items:
              - key: custom.py
                path: custom.py
            name: <resourcename>-extra-config
        - name: shared-volume
          persistentVolumeClaim:
            claimName: my-external-volume-claim

      init_container_extra_volume_mounts: |
        - name: shared-volume
          mountPath: /shared

      init_container_extra_commands: |
        # set proper permissions (rwx) for the awx user
        chmod 775 /shared
        chgrp 1000 /shared

      ee_extra_volume_mounts: |
        - name: ansible-cfg
          mountPath: /etc/ansible/ansible.cfg
          subPath: ansible.cfg

      task_extra_volume_mounts: |
        - name: custom-py
          mountPath: /etc/tower/conf.d/custom.py
          subPath: custom.py
        - name: shared-volume
          mountPath: /shared
```

> :warning: **Volume and VolumeMount names cannot contain underscores(_)**

#### Default execution environments from private registries

In order to register default execution environments from private registries, the Custom Resource needs to know about the pull credentials. Those credentials should be stored as a secret and either specified as `ee_pull_credentials_secret` at the CR spec level, or simply be present on the namespace under the name `<resourcename>-ee-pull-credentials` . Instance initialization will register a `Container registry` type credential on the deployed instance and assign it to the registered default execution environments.

The secret should be formated as follows:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: <resourcename>-ee-pull-credentials
  namespace: <target namespace>
stringData:
  url: <registry url. i.e. quay.io>
  username: <username to connect as>
  password: <password to connect with>
  ssl_verify: <Optional attribute. Whether verify ssl connection or not. Accepted values "True" (default), "False" >
type: Opaque
```

##### Control plane ee from private registry
The images listed in "ee_images" will be added as globally available Execution Environments. The "control_plane_ee_image" will be used to run project updates. In order to use a private image for any of these you'll need to use `image_pull_secrets` to provide a list of k8s pull secrets to access it. Currently the same secret is used for any of these images supplied at install time.

You can create `image_pull_secret`
```
kubectl create secret <resoucename>-cp-pull-credentials regcred --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
```
If you need more control (for example, to set a namespace or a label on the new secret) then you can customise the Secret before storing it

Example spec file extra-config

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: <resoucename>-cp-pull-credentials
  namespace: <target namespace>
data:
  .dockerconfigjson: <base64 docker config>
type: kubernetes.io/dockerconfigjson
```

#### Exporting Environment Variables to Containers

If you need to export custom environment variables to your containers.

| Name           | Description                                         | Default |
| -------------- | --------------------------------------------------- | ------- |
| task_extra_env | Environment variables to be added to Task container | ''      |
| web_extra_env  | Environment variables to be added to Web container  | ''      |
| ee_extra_env   | Environment variables to be added to EE container   | ''      |

> :warning: The `ee_extra_env` will only take effect to the globally available Execution Environments. For custom `ee`, please [customize the Pod spec](https://docs.ansible.com/ansible-tower/latest/html/administration/external_execution_envs.html#customize-the-pod-spec).

Example configuration of environment variables

```yaml
  spec:
    task_extra_env: |
      - name: MYCUSTOMVAR
        value: foo
    web_extra_env: |
      - name: MYCUSTOMVAR
        value: foo
    ee_extra_env: |
      - name: MYCUSTOMVAR
        value: foo
```

#### CSRF Cookie Secure Setting

With `csrf_cookie_secure`, you can pass the value for `CSRF_COOKIE_SECURE` to `/etc/tower/settings.py`

| Name               | Description        | Default |
| ------------------ | ------------------ | ------- |
| csrf_cookie_secure | CSRF Cookie Secure | ''      |

Example configuration of the `csrf_cookie_secure` setting:

```yaml
  spec:
    csrf_cookie_secure: 'False'
```

#### Session Cookie Secure Setting

With `session_cookie_secure`, you can pass the value for `SESSION_COOKIE_SECURE` to `/etc/tower/settings.py`

| Name                  | Description           | Default |
| --------------------- | --------------------- | ------- |
| session_cookie_secure | Session Cookie Secure | ''      |

Example configuration of the `session_cookie_secure` setting:

```yaml
  spec:
    session_cookie_secure: 'False'
```

#### Extra Settings

With`extra_settings`, you can pass multiple custom settings via the `awx-operator`. The parameter `extra_settings`  will be appended to the `/etc/tower/settings.py` and can be an alternative to the `extra_volumes` parameter.

| Name           | Description    | Default |
| -------------- | -------------- | ------- |
| extra_settings | Extra settings | ''      |

Example configuration of `extra_settings` parameter

```yaml
  spec:
    extra_settings:
      - setting: MAX_PAGE_SIZE
        value: "500"

      - setting: AUTH_LDAP_BIND_DN
        value: "cn=admin,dc=example,dc=com"
```

#### No Log
Configure no_log for tasks with no_log

| Name   | Description          | Default |
| ------ | -------------------- | ------- |
| no_log | No log configuration | 'true'  |

Example configuration of `no_log` parameter

```yaml
  spec:
    no_log: 'true'
```

#### Auto upgrade
With this parameter you can influence the behaviour during an operator upgrade.  
If set to `true`, the operator will upgrade the specific instance directly.  
When the value is set to `false`, and we have a running deployment, the operator will not update the AWX instance.  
This can be useful when you have multiple AWX instances which you want to upgrade step by step instead of all at once.  


| Name         | Description                        | Default |
| -------------| ---------------------------------- | ------- |
| auto_upgrade | Automatic upgrade of AWX instances | true    |

Example configuration of `auto_upgrade` parameter

```yaml
  spec:
    auto_upgrade: true
```

##### Upgrade of instances without auto upgrade

There are two ways to upgrade instances which are marked with the 'auto_upgrade: false' flag.  

Changing flags:

- change the auto_upgrade flag on your AWX object to true  
- wait until the upgrade process of that instance is finished
- change the auto_upgrade flag on your AWX object back to false  

Delete the deployment:

- delete the deployment object of your AWX instance  
```
$ kubectl -n awx delete deployment <yourInstanceName> 
```
- wait until the instance gets redeployed  


#### Service Account

If you need to modify some `ServiceAccount` proprieties

| Name                        | Description                       | Default |
| --------------------------- | --------------------------------- | ------- |
| service_account_annotations | Annotations to the ServiceAccount | ''      |

Example configuration of environment variables

```yaml
  spec:
    service_account_annotations: |
      eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME>
```


### Uninstall ###

To uninstall an AWX deployment instance, you basically need to remove the AWX kind related to that instance. For example, to delete an AWX instance named awx-demo, you would do:

```
$ kubectl delete awx awx-demo
awx.awx.ansible.com "awx-demo" deleted
```

Deleting an AWX instance will remove all related deployments and statefulsets, however, persistent volumes and secrets will remain. To enforce secrets also getting removed, you can use `garbage_collect_secrets: true`.

### Upgrading

To upgrade AWX, it is recommended to upgrade the awx-operator to the version that maps to the desired version of AWX.  To find the version of AWX that will be installed by the awx-operator by default, check the version specified in the `image_version` variable in `roles/installer/defaults/main.yml` for that particular release.

Apply the awx-operator.yml for that release to upgrade the operator, and in turn also upgrade your AWX deployment.

#### v0.14.0

##### Cluster-scope to Namespace-scope considerations

Starting with awx-operator 0.14.0, AWX can only be deployed in the namespace that the operator exists in. This is called a namespace-scoped operator. If you are upgrading from an earlier version, you will want to
delete your existing `awx-operator` service account, role and role binding.

##### Project is now based on v1.x of the operator-sdk project

Starting with awx-operator 0.14.0, the project is now based on operator-sdk 1.x. You may need to manually delete your old operator Deployment to avoid issues.

##### Steps to upgrade

Delete your old AWX Operator and existing `awx-operator` service account, role and role binding in `default` namespace first:

```
$ kubectl -n default delete deployment awx-operator
$ kubectl -n default delete serviceaccount awx-operator
$ kubectl -n default delete clusterrolebinding awx-operator
$ kubectl -n default delete clusterrole awx-operator
```

Then install the new AWX Operator by following the instructions in [Basic Install](#basic-install-on-existing-cluster). The `NAMESPACE` environment variable have to be the name of the namespace in which your old AWX instance resides.

Once the new AWX Operator is up and running, your AWX deployment will also be upgraded.

## Contributing

Please visit [our contributing guidelines](https://github.com/ansible/awx-operator/blob/devel/CONTRIBUTING.md).


## Release Process

The first step is to create a draft release. Typically this will happen in the [Stage Release](https://github.com/ansible/awx/blob/devel/.github/workflows/stage.yml) workflow for AWX and you dont need to do it as a separate step.

If you need to do an independent release of the operator, you can run the [Stage Release](https://github.com/ansible/awx-operator/blob/devel/.github/workflows/stage.yml) in the awx-operator repo. Both of these workflows will run smoke tests, so there is no need to do this manually.

After the draft release is created, publish it and the [Promote AWX Operator image](https://github.com/ansible/awx-operator/blob/devel/.github/workflows/promote.yaml) will run, which will:

- Publish image to Quay
- Release Helm chart

## Author

This operator was originally built in 2019 by [Jeff Geerling](https://www.jeffgeerling.com) and is now maintained by the Ansible Team

## Code of Conduct

We ask all of our community members and contributors to adhere to the [Ansible code of conduct](http://docs.ansible.com/ansible/latest/community/code_of_conduct.html). If you have questions or need assistance, please reach out to our community team at [codeofconduct@ansible.com](mailto:codeofconduct@ansible.com)

## Get Involved

We welcome your feedback and ideas. The AWX operator uses the same mailing list and IRC chanel as AWX itself. Here's how to reach us with feedback and questions:

- Join the `#ansible-awx` channel on irc.libera.chat
- Join the [mailing list](https://groups.google.com/forum/#!forum/awx-project)
