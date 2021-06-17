# AWX Operator

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![Build Status](https://github.com/ansible/awx-operator/workflows/CI/badge.svg?event=push)](https://github.com/ansible/awx-operator/actions)

An [Ansible AWX](https://github.com/ansible/awx) operator for Kubernetes built with [Operator SDK](https://github.com/operator-framework/operator-sdk) and Ansible.

# Table of Contents

<!--ts-->
* [AWX Operator](#awx-operator)
* [Table of Contents](#table-of-contents)
   * [Purpose](#purpose)
   * [Usage](#usage)
      * [Basic Install](#basic-install)
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
         * [Privileged Tasks](#privileged-tasks)
         * [Containers Resource Requirements](#containers-resource-requirements)
         * [LDAP Certificate Authority](#ldap-certificate-authority)
         * [Persisting Projects Directory](#persisting-projects-directory)
         * [Custom Volume and Volume Mount Options](#custom-volume-and-volume-mount-options)
         * [Exporting Environment Variables to Containers](#exporting-environment-variables-to-containers)
         * [Extra Settings](#extra-settings)
         * [Service Account](#service-account)
   * [Upgrading](#upgrading)
   * [Contributing](#contributing)
   * [Release Process](#release-process)
      * [Verifiy Functionality](#verify-functionality)
      * [Update Version](#update-version)
      * [Commit / Create Release](#commit--create-release)
   * [Author](#author)
<!--te-->

## Purpose

This operator is meant to provide a more Kubernetes-native installation method for AWX via an AWX Custom Resource Definition (CRD).

> :warning: The operator is not supported by Red Hat, and is in **alpha** status. For now, use it at your own risk!

## Usage

### Basic Install

This Kubernetes Operator is meant to be deployed in your Kubernetes cluster(s) and can manage one or more AWX instances in any namespace.

For testing purposes, the `awx-operator` can be deployed on a [Minikube](https://minikube.sigs.k8s.io/docs/) cluster. Due to different OS and hardware environments, please refer to the official Minikube documentation for further information.

```bash
$ minikube start --addons=ingress --cpus=4 --cni=flannel --install-addons=true \
    --kubernetes-version=stable --memory=6g
😄  minikube v1.20.0 on Fedora 34
✨  Using the kvm2 driver based on user configuration
👍  Starting control plane node minikube in cluster minikube
🔥  Creating kvm2 VM (CPUs=4, Memory=6144MB, Disk=20000MB) ...
🐳  Preparing Kubernetes v1.20.2 on Docker 20.10.6 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring Flannel (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image docker.io/jettech/kube-webhook-certgen:v1.5.1
    ▪ Using image k8s.gcr.io/ingress-nginx/controller:v0.44.0
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
    ▪ Using image docker.io/jettech/kube-webhook-certgen:v1.5.1
🔎  Verifying ingress addon...
🌟  Enabled addons: storage-provisioner, default-storageclass, ingress
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

Once Minikube is deployed, check if the node(s) and `kube-apiserver` communication is working as expected.

```bash
$ kubectl get nodes
NAME       STATUS   ROLES                  AGE     VERSION
minikube   Ready    control-plane,master   6m28s   v1.20.2

$ kubectl get pods -A
NAMESPACE       NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx   ingress-nginx-admission-create-tjk94        0/1     Completed   0          6m4s
ingress-nginx   ingress-nginx-admission-patch-r4pl6         0/1     Completed   0          6m4s
ingress-nginx   ingress-nginx-controller-5d88495688-sbtp9   1/1     Running     0          6m4s
kube-system     coredns-74ff55c5b-2wz6n                     1/1     Running     0          6m4s
kube-system     etcd-minikube                               1/1     Running     0          6m13s
kube-system     kube-apiserver-minikube                     1/1     Running     0          6m13s
kube-system     kube-controller-manager-minikube            1/1     Running     0          6m13s
kube-system     kube-flannel-ds-amd64-lw7lv                 1/1     Running     0          6m3s
kube-system     kube-proxy-lcxx7                            1/1     Running     0          6m3s
kube-system     kube-scheduler-minikube                     1/1     Running     0          6m13s
kube-system     storage-provisioner                         1/1     Running     1          6m17s
```

Now you need to deploy AWX Operator into your cluster. Start by going to https://github.com/ansible/awx-operator/releases and making note of the latest release. Replace `<TAG>` in the URL `https://raw.githubusercontent.com/ansible/awx-operator/<TAG>/deploy/awx-operator.yaml` with the version you are deploying.

```bash
$ kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/<TAG>/deploy/awx-operator.yaml
customresourcedefinition.apiextensions.k8s.io/awxs.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxbackups.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxrestores.awx.ansible.com created
clusterrole.rbac.authorization.k8s.io/awx-operator created
clusterrolebinding.rbac.authorization.k8s.io/awx-operator created
serviceaccount/awx-operator created
deployment.apps/awx-operator created
```

Wait a few minutes and you should have the `awx-operator` running.

```bash
$ kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
awx-operator-7dbf9db9d7-z9hqx   1/1     Running   0          50s
```

Then create a file named `awx-demo.yml` with the suggested content. The `metadata.name` you provide, will be the name of the resulting AWX deployment.  If you deploy more than one AWX instance to the same namespace, be sure to use unique names.

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
  ingress_type: none
  hostname: awx-demo.example.com
```

Finally, use `kubectl` to create the awx instance in your cluster:

```bash
$ kubectl apply -f awx-demo.yml
awx.awx.ansible.com/awx-demo created
```

After a few minutes, the new AWX instance will be deployed. One can look at the operator pod logs in order to know where the installation process is at. This can be done by running the following command: `kubectl logs -f deployments/awx-operator`.

```bash
$ kubectl get pods -l "app.kubernetes.io/managed-by=awx-operator"
NAME                        READY   STATUS    RESTARTS   AGE
awx-demo-77d96f88d5-pnhr8   4/4     Running   0          3m24s
awx-demo-postgres-0         1/1     Running   0          3m34s

$ kubectl get svc -l "app.kubernetes.io/managed-by=awx-operator"
NAME                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
awx-demo-postgres   ClusterIP   None           <none>        5432/TCP       4m4s
awx-demo-service    NodePort    10.109.40.38   <none>        80:31006/TCP   3m56s
```

Once deployed, the AWX instance will be accessible by the command `minikube service awx-demo-service --url`.

By default, the admin user is `admin` and the password is available in the `<resourcename>-admin-password` secret. To retrieve the admin password, run `kubectl get secret <resourcename>-admin-password -o jsonpath="{.data.password}" | base64 --decode`

You just completed the most basic install of an AWX instance via this operator. Congratulations!!!!

For an example using the Nginx Controller in Minukube, don't miss our [demo video](https://asciinema.org/a/416946).

[![asciicast](https://raw.githubusercontent.com/ansible/awx-operator/devel/docs/awx-demo.svg)](https://asciinema.org/a/416946)

### Admin user account configuration

There are three variables that are customizable for the admin user account creation.

| Name                        | Description                                  | Default          |
| --------------------------- | -------------------------------------------- | ---------------- |
| admin_user                  | Name of the admin user                       | admin            |
| admin_email                 | Email of the admin user                      | test@example.com |
| admin_password_secret       | Secret that contains the admin user password | Empty string     |


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


### Network and TLS Configuration

#### Service Type

If the `service_type` is not specified, the `ClusterIP` service will be used for your AWX Tower service.

The `service_type` supported options are: `ClusterIP`, `LoadBalancer` and `NodePort`.

The following variables are customizable for any `service_type`

| Name                                  | Description                                   | Default                           |
| ------------------------------------- | --------------------------------------------- | --------------------------------- |
| service_labels                  | Add custom labels                             | Empty string                      |

```yaml
---
spec:
  ...
  service_type: ClusterIP
  service_labels: |
    environment: testing
```

  * LoadBalancer

The following variables are customizable only when `service_type=LoadBalancer`

| Name                           | Description                              | Default       |
| ------------------------------ | ---------------------------------------- | ------------- |
| loadbalancer_annotations | LoadBalancer annotations                 | Empty string  |
| loadbalancer_protocol    | Protocol to use for Loadbalancer ingress | http          |
| loadbalancer_port        | Port used for Loadbalancer ingress       | 80            |

```yaml
---
spec:
  ...
  service_type: LoadBalancer
  loadbalancer_protocol: https
  loadbalancer_port: 443
  loadbalancer_annotations: |
    environment: testing
  service_labels: |
    environment: testing
```

When setting up a Load Balancer for HTTPS you will be required to set the `loadbalancer_port` to move the port away from `80`.

The HTTPS Load Balancer also uses SSL termination at the Load Balancer level and will offload traffic to AWX over HTTP.

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

| Name                       | Description                              | Default                      |
| -------------------------- | ---------------------------------------- | ---------------------------- |
| ingress_annotations        | Ingress annotations                      | Empty string                 |
| ingress_tls_secret         | Secret that contains the TLS information | Empty string                 |
| hostname                   | Define the FQDN                          | {{ meta.name }}.example.com  |

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

| Name                                  | Description                                   | Default                                                 |
| ------------------------------------- | --------------------------------------------- | --------------------------------------------------------|
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

In order for the AWX instance to rely on an external database, the Custom Resource needs to know about the connection details. Those connection details should be stored as a secret and either specified as `postgres_configuration_secret` at the CR spec level, or simply be present on the namespace under the name `<resourcename>-postgres-configuration`.


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

> It is possible to set a specific username, password, port, or database, but still have the database managed by the operator. In this case, when creating the postgres-configuration secret, the `type: managed` field should be added.  

**Note**: The variable `sslmode` is valid for `external` databases only. The allowed values are: `prefer`, `disable`, `allow`, `require`, `verify-ca`, `verify-full`.

#### Migrating data from an old AWX instance

For instructions on how to migrate from an older version of AWX, see [migration.md](./docs/migration.md).

#### Managed PostgreSQL Service

If you don't have access to an external PostgreSQL service, the AWX operator can deploy one for you along side the AWX instance itself.

The following variables are customizable for the managed PostgreSQL service

| Name                                 | Description                                | Default                           |
| ------------------------------------ | ------------------------------------------ | --------------------------------- |
| postgres_image                       | Path of the image to pull                  | postgres:12                       |
| postgres_resource_requirements       | PostgreSQL container resource requirements | Empty object                      |
| postgres_storage_requirements        | PostgreSQL container storage requirements  | requests: {storage: 8Gi}          |
| postgres_storage_class               | PostgreSQL PV storage class                | Empty string                      |
| postgres_data_path                   | PostgreSQL data path                       | `/var/lib/postgresql/data/pgdata` |

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
```

**Note**: If `postgres_storage_class` is not defined, Postgres will store it's data on a volume using the default storage class for your cluster.

### Advanced Configuration

#### Deploying a specific version of AWX

There are a few variables that are customizable for awx the image management.

| Name                      | Description                |
| --------------------------| -------------------------- |
| image                     | Path of the image to pull  |
| image_version             | Image version to pull      |
| image_pull_policy         | The pull policy to adopt   |
| image_pull_secret         | The pull secret to use     |
| ee_images                 | A list of EEs to register  |
| redis_image               | Path of the image to pull  |
| redis_image_version       | Image version to pull      |

Example of customization could be:

```yaml
---
spec:
  ...
  image: myorg/my-custom-awx
  image_version: latest
  image_pull_policy: Always
  image_pull_secret: pull_secret_name
  ee_images:
    - name: my-custom-awx-ee
      image: myorg/my-custom-awx-ee
```

**Note**: The `image` and `image_version` are intended for local mirroring scenarios. Please note that using a version of AWX other than the one bundled with the `awx-operator` is **not** supported. For the default values, check the [main.yml](https://github.com/ansible/awx-operator/blob/devel/roles/installer/defaults/main.yml) file.

#### Privileged Tasks

Depending on the type of tasks that you'll be running, you may find that you need the task pod to run as `privileged`. This can open yourself up to a variety of security concerns, so you should be aware (and verify that you have the privileges) to do this if necessary. In order to toggle this feature, you can add the following to your custom resource:

```yaml
---
spec:
  ...
  task_privileged: true
```

If you are attempting to do this on an OpenShift cluster, you will need to grant the `awx` ServiceAccount the `privileged` SCC, which can be done with:

```sh
#> oc adm policy add-scc-to-user privileged -z awx
```

Again, this is the most relaxed SCC that is provided by OpenShift, so be sure to familiarize yourself with the security concerns that accompany this action.


#### Containers Resource Requirements

The resource requirements for both, the task and the web containers are configurable - both the lower end (requests) and the upper end (limits).

| Name                             | Description                                      | Default                             |
| -------------------------------- | ------------------------------------------------ | ----------------------------------- |
| web_resource_requirements        | Web container resource requirements              | requests: {cpu: 1000m, memory: 2Gi} |
| task_resource_requirements       | Task container resource requirements             | requests: {cpu: 500m, memory: 1Gi}  |
| ee_resource_requirements         | EE control plane container resource requirements | requests: {cpu: 500m, memory: 1Gi}  |

Example of customization could be:

```yaml
---
spec:
  ...
  web_resource_requirements:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  task_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1000m
      memory: 2Gi
  ee_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1000m
      memory: 2Gi
```

#### Assigning AWX pods to specific nodes

You can constrain the AWX pods created by the operator to run on a certain subset of nodes. `node_selector` and `postgres_selector` constrains
the AWX pods to run only on the nodes that match all the specified key/value pairs. `tolerations` and `postgres_tolerations` allow the AWX
pods to be scheduled onto nodes with matching taints.


| Name                           | Description                 | Default |
| -------------------------------| --------------------------- | ------- |
| postgres_image                 | Path of the image to pull   | 12      |
| postgres_image_version         | Image version to pull       | 12      |
| node_selector                  | AWX pods' nodeSelector      | ''      |
| tolerations                    | AWX pods' tolerations       | ''      |
| postgres_selector              | Postgres pods' nodeSelector | ''      |
| postgres_tolerations           | Postgres pods' tolerations  | ''      |

Example of customization could be:

```yaml
---
spec:
  ...
  node_selector: |
    disktype: ssd
    kubernetes.io/arch: amd64
    kubernetes.io/os: linux
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

#### LDAP Certificate Authority

If the variable `ldap_cacert_secret` is provided, the operator will look for a the data field `ldap-ca.crt` in the specified secret.

| Name                             | Description                             | Default |
| -------------------------------- | --------------------------------------- | --------|
| ldap_cacert_secret               | LDAP Certificate Authority secret name  |  ''     |


Example of customization could be:

```yaml
---
spec:
  ...
  ldap_cacert_secret: <resourcename>-ldap-ca-cert
```

To create the secret, you can use the command below:

```sh
# kubectl create secret generic <resourcename>-ldap-ca-cert --from-file=ldap-ca.crt=<PATH/TO/YOUR/CA/PEM/FILE>
```

#### Persisting Projects Directory

In cases which you want to persist the `/var/lib/projects` directory, there are few variables that are customizable for the `awx-operator`.

| Name                               | Description                                                                                          | Default        |
| -----------------------------------| ---------------------------------------------------------------------------------------------------- | ---------------|
| projects_persistence         | Whether or not the /var/lib/projects directory will be persistent                                    |  false         |
| projects_storage_class       | Define the PersistentVolume storage class                                                            |  ''            |
| projects_storage_size        | Define the PersistentVolume size                                                                     |  8Gi           |
| projects_storage_access_mode | Define the PersistentVolume access mode                                                              |  ReadWriteMany |
| projects_existing_claim      | Define an existing PersistentVolumeClaim to use (cannot be combined with `projects_storage_*`) |  ''            |

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

| Name                           | Description                                              | Default |
| ------------------------------ | -------------------------------------------------------- | ------- |
| extra_volumes                  | Specify extra volumes to add to the application pod      | ''      |
| web_extra_volume_mounts        | Specify volume mounts to be added to Web container       | ''      |
| task_extra_volume_mounts       | Specify volume mounts to be added to Task container      | ''      |
| ee_extra_volume_mounts         | Specify volume mounts to be added to Execution container | ''      |

Example configuration for ConfigMap

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
The images listed in "ee_images" will be added as globally available Execution Environments. The "control_plane_ee_image" will be used to run project updates. In order to use a private image for any of these you'll need to use `image_pull_secret` to provide a k8s pull secret to access it. Currently the same secret is used for any of these images supplied at install time.

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
      ee_extra_volume_mounts: |
        - name: ansible-cfg
          mountPath: /etc/ansible/ansible.cfg
          subPath: ansible.cfg

      task_extra_volume_mounts: |
        - name: custom-py
          mountPath: /etc/tower/conf.d/custom.py
          subPath: custom.py

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

```

> :warning: **Volume and VolumeMount names cannot contain underscores(_)**

#### Exporting Environment Variables to Containers

If you need to export custom environment variables to your containers.

| Name                          | Description                                              | Default |
| ----------------------------- | -------------------------------------------------------- | ------- |
| task_extra_env                | Environment variables to be added to Task container      | ''      |
| web_extra_env                 | Environment variables to be added to Web container       | ''      |
| ee_extra_env                  | Environment variables to be added to EE container        | ''      |

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

#### Extra Settings

With`extra_settings`, you can pass multiple custom settings via the `awx-operator`. The parameter `extra_settings`  will be appended to the `/etc/tower/settings.py` and can be an alternative to the `extra_volumes` parameter.

| Name                          | Description                                              | Default |
| ----------------------------- | -------------------------------------------------------- | ------- |
| extra_settings                | Extra settings                                           | ''      |

Example configuration of `extra_settings` parameter

```yaml
  spec:
    extra_settings:
      - setting: MAX_PAGE_SIZE
        value: "500"

      - setting: AUTH_LDAP_BIND_DN
        value: "cn=admin,dc=example,dc=com"
```

#### Service Account

If you need to modify some `ServiceAccount` proprieties

| Name                          | Description                                              | Default |
| ----------------------------- | -------------------------------------------------------- | ------- |
| service_account_annotations   | Annotations to the ServiceAccount                        | ''      |

Example configuration of environment variables

```yaml
  spec:
    service_account_annotations: |
      eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME>
```

### Upgrading

To upgrade AWX, it is recommended to upgrade the awx-operator to the version that maps to the desired version of AWX.  To find the version of AWX that will be installed by the awx-operator by default, check the version specified in the `image_version` variable in `roles/installer/defaults/main.yml` for that particular release.

Apply the awx-operator.yml for that release to upgrade the operator, and in turn also upgrade your AWX deployment.


## Contributing

Please visit [our contributing guidelines](https://github.com/ansible/awx-operator/blob/devel/CONTRIBUTING.md).


## Release Process

There are a few moving parts to this project:

  * The `awx-operator` container image which powers AWX Operator
  * The `awx-operator.yaml` file, which initially deploys the Operator
  * The ClusterServiceVersion (CSV), which is generated as part of the bundle and needed for the olm-catalog

Each of these must be appropriately built in preparation for a new tag:

### Update version and files

Update the awx-operator version:

  - `ansible/group_vars/all`

Once the version has been updated, run from the root of the repo:

```sh
#> ansible-playbook ansible/chain-operator-files.yml
```

Generate the olm-catalog bundle.

```bash
$ operator-sdk generate bundle --operator-name awx-operator --version <new_tag>
```

> This should be done with operator-sdk v0.19.4.  

> It is a good idea to use the [build script](./build.sh) at this point to build the catalog and test out installing it in Operator Hub.

### Verify Functionality

Run the following command inside this directory:

```sh
#> operator-sdk build quay.io/<user>/awx-operator:<new-version>
```

Then push the generated image to Docker Hub:

```sh
#> docker push quay.io/<user>/awx-operator:<new-version>
```

After it is built, test it on a local cluster:


```sh
#> minikube start --memory 6g --cpus 4
#> minikube addons enable ingress
#> ansible-playbook ansible/deploy-operator.yml -e operator_image=quay.io/<user>/awx-operator -e operator_version=<new-version> -e pull_policy=Always
#> kubectl create namespace example-awx
#> ansible-playbook ansible/instantiate-awx-deployment.yml -e namespace=example-awx -e image=quay.io/<user>/awx -e service_type=nodeport
#> # Verify that the awx-task and awx-web containers are launched 
#> # with the right version of the awx image
#> minikube delete
```

### Update changelog

Generate a list of commits between the versions and add it to the [changelog](./CHANGELOG.md).
```sh
#> git log --no-merges --pretty="- %s (%an) - %h " <old_tag>..<new_tag>
```

### Commit / Create Release

If everything works, commit the updated version, then [publish a new release](https://github.com/ansible/awx-operator/releases/new) using the same version you used in `ansible/group_vars/all`.

After creating the release, [this GitHub Workflow](https://github.com/ansible/awx-operator/blob/devel/.github/workflows/release.yaml) will run and publish the new image to quay.io.

## Author

This operator was originally built in 2019 by [Jeff Geerling](https://www.jeffgeerling.com) and is now maintained by the Ansible Team
