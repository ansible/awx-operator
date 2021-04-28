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
         * [Ingress Type](#ingress-type)
         * [TLS Termination](#tls-termination)
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
   * [Development](#development)
      * [Testing](#testing)
         * [Testing in Docker](#testing-in-docker)
         * [Testing in Minikube](#testing-in-minikube)
      * [Generating a bundle](#generating-a-bundle)
   * [Release Process](#release-process)
      * [Build a new release](#build-a-new-release)
      * [Build a new version of the operator yaml file](#build-a-new-version-of-the-operator-yaml-file)
   * [Author](#author)
<!--te-->

## Purpose

This operator is meant to provide a more Kubernetes-native installation method for AWX via an AWX Custom Resource Definition (CRD).

Note that the operator is not supported by Red Hat, and is in **alpha** status. For now, use it at your own risk!

## Usage

### Basic Install

This Kubernetes Operator is meant to be deployed in your Kubernetes cluster(s) and can manage one or more AWX instances in any namespace.

First, you need to deploy AWX Operator into your cluster. Start by going to https://github.com/ansible/awx-operator/releases and making note of the latest release.

Replace `<tag>` in the URL below with the version you are deploying:

```bash
#> kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/<tag>/deploy/awx-operator.yaml
```

Then create a file named `my-awx.yml` with the following contents:

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
```

> The metadata.name you provide, will be the name of the resulting AWX deployment.  If you deploy more than one to the same namespace, be sure to use unique names.

Finally, use `kubectl` to create the awx instance in your cluster:

```bash
#> kubectl apply -f my-awx.yml
```

After a few minutes, the new AWX instance will be deployed. One can look at the operator pod logs in order to know where the installation process is at. This can be done by running the following command: `kubectl logs -f deployments/awx-operator`.

Once deployed, the AWX instance will be accessible at `http://awx.mycompany.com/` (assuming your cluster has an Ingress controller configured).

By default, the admin user is `admin` and the password is available in the `<resourcename>-admin-password` secret. To retrieve the admin password, run `kubectl get secret <resourcename>-admin-password -o jsonpath="{.data.password}" | base64 --decode`


You just completed the most basic install of an AWX instance via this operator. Congratulations !

### Admin user account configuration

There are three variables that are customizable for the admin user account creation.

| Name                        | Description                                  | Default          |
| --------------------------- | -------------------------------------------- | ---------------- |
| tower_admin_user            | Name of the admin user                       | admin            |
| tower_admin_email           | Email of the admin user                      | test@example.com |
| tower_admin_password_secret | Secret that contains the admin user password | Empty string     |


> :warning: **tower_admin_password_secret must be a Kubernetes secret and not your text clear password**.

If `tower_admin_password_secret` is not provided, the operator will look for a secret named `<resourcename>-admin-password` for the admin password. If it is not present, the operator will generate a password and create a Secret from it named `<resourcename>-admin-password`.

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

#### Ingress Type

By default, the AWX operator is not opinionated and won't force a specific ingress type on you. So, if `tower_ingress_type` is not specified as part of the Custom Resource specification, it will default to `none` and nothing ingress-wise will be created.

The AWX operator provides support for four kinds of `Ingress` to access AWX: `Ingress`, `Route`,  `LoadBalancer` and `NodePort`, To toggle between these options, you can add the following to your AWX CR:

  * Route

```yaml
---
spec:
  ...
  tower_ingress_type: Route
```

  * Ingress

```yaml
---
spec:
  ...
  tower_ingress_type: Ingress
  tower_hostname: awx.mycompany.com
```

  * LoadBalancer

```yaml
---
spec:
  ...
  tower_ingress_type: LoadBalancer
  tower_loadbalancer_protocol: http
```

  * NodePort

```yaml
---
spec:
  ...
  tower_ingress_type: NodePort
```

The AWX `Service` that gets created will have a `type` set based on the `tower_ingress_type` being used:

| Ingress Type `tower_ingress_type`     | Service Type   |
| ------------------------------------- | -------------- |
| `LoadBalancer`                        | `LoadBalancer` |
| `NodePort`                            | `NodePort`     |
| `Ingress` or `Route` or not specified | `ClusterIP`    |

#### TLS Termination

  * Route

The following variables are customizable to specify the TLS termination procedure when `Route` is picked as an Ingress

| Name                                  | Description                                   | Default                           |
| ------------------------------------- | --------------------------------------------- | --------------------------------- |
| tower_route_host                      | Common name the route answers for             | Empty string                      |
| tower_route_tls_termination_mechanism | TLS Termination mechanism (Edge, Passthrough) | Edge                              |
| tower_route_tls_secret                | Secret that contains the TLS information      | Empty string                      |

  * Ingress

The following variables are customizable to specify the TLS termination procedure when `Ingress` is picked as an Ingress

| Name                       | Description                              | Default       |
| -------------------------- | ---------------------------------------- | ------------- |
| tower_ingress_annotations  | Ingress annotations                      | Empty string  |
| tower_ingress_tls_secret   | Secret that contains the TLS information | Empty string  |

  * LoadBalancer

The following variables are customizable to specify the TLS termination procedure when `LoadBalancer` is picked as an Ingress

| Name                           | Description                              | Default       |
| ------------------------------ | ---------------------------------------- | ------------- |
| tower_loadbalancer_annotations | LoadBalancer annotations                 | Empty string  |
| tower_loadbalancer_protocol    | Protocol to use for Loadbalancer ingress | http          |
| tower_loadbalancer_port        | Port used for Loadbalancer ingress       | 80            |

When setting up a Load Balancer for HTTPS you will be required to set the `tower_loadbalancer_port` to move the port away from `80`.

The HTTPS Load Balancer also uses SSL termination at the Load Balancer level and will offload traffic to AWX over HTTP.

### Database Configuration

#### External PostgreSQL Service

In order for the AWX instance to rely on an external database, the Custom Resource needs to know about the connection details. Those connection details should be stored as a secret and either specified as `tower_postgres_configuration_secret` at the CR spec level, or simply be present on the namespace under the name `<resourcename>-postgres-configuration`.


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
type: Opaque
```

**Note**: The variable `sslmode` is valid for `external` databases only. The allowed values are: `prefer`, `disable`, `allow`, `require`, `verify-ca`, `verify-full`.

#### Migrating data from an old AWX instance

For instructions on how to migrate from an older version of AWX, see [migration.md](./docs/migration.md).

#### Managed PostgreSQL Service

If you don't have access to an external PostgreSQL service, the AWX operator can deploy one for you along side the AWX instance itself.

The following variables are customizable for the managed PostgreSQL service

| Name                                 | Description                                | Default                           |
| ------------------------------------ | ------------------------------------------ | --------------------------------- |
| tower_postgres_image                 | Path of the image to pull                  | postgres:12                       |
| tower_postgres_resource_requirements | PostgreSQL container resource requirements | Empty object                      |
| tower_postgres_storage_requirements  | PostgreSQL container storage requirements  | requests: {storage: 8Gi}          |
| tower_postgres_storage_class         | PostgreSQL PV storage class                | Empty string                      |
| tower_postgres_data_path             | PostgreSQL data path                       | `/var/lib/postgresql/data/pgdata` |

Example of customization could be:

```yaml
---
spec:
  ...
  tower_postgres_resource_requirements:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: 1
      memory: 4Gi
  tower_postgres_storage_requirements:
    requests:
      storage: 8Gi
    limits:
      storage: 50Gi
  tower_postgres_storage_class: fast-ssd
```

**Note**: If `tower_postgres_storage_class` is not defined, Postgres will store it's data on a volume using the default storage class for your cluster.

### Advanced Configuration

#### Deploying a specific version of AWX

There are a few variables that are customizable for awx the image management.

| Name                      | Description                |
| --------------------------| -------------------------- |
| tower_image               | Path of the image to pull  |
| tower_image_version       | Image version to pull      |
| tower_image_pull_policy   | The pull policy to adopt   |
| tower_image_pull_secret   | The pull secret to use     |
| tower_ee_images           | A list of EEs to register  |
| tower_redis_image         | Path of the image to pull  |
| tower_redis_image_version | Image version to pull      |

Example of customization could be:

```yaml
---
spec:
  ...
  tower_image: myorg/my-custom-awx
  tower_image_version: latest
  tower_image_pull_policy: Always
  tower_image_pull_secret: pull_secret_name
  tower_ee_images:
    - name: my-custom-awx-ee
      image: myorg/my-custom-awx-ee
```

**Note**: The `tower_image` and `tower_image_version` are intended for local mirroring scenarios. Please note that using a version of AWX other than the one bundled with the `awx-operator` is **not** supported. For the default values, check the [main.yml](https://github.com/ansible/awx-operator/blob/devel/roles/installer/defaults/main.yml) file.

#### Privileged Tasks

Depending on the type of tasks that you'll be running, you may find that you need the task pod to run as `privileged`. This can open yourself up to a variety of security concerns, so you should be aware (and verify that you have the privileges) to do this if necessary. In order to toggle this feature, you can add the following to your custom resource:

```yaml
---
spec:
  ...
  tower_task_privileged: true
```

If you are attempting to do this on an OpenShift cluster, you will need to grant the `awx` ServiceAccount the `privileged` SCC, which can be done with:

```sh
#> oc adm policy add-scc-to-user privileged -z awx
```

Again, this is the most relaxed SCC that is provided by OpenShift, so be sure to familiarize yourself with the security concerns that accompany this action.


#### Containers Resource Requirements

The resource requirements for both, the task and the web containers are configurable - both the lower end (requests) and the upper end (limits).

| Name                             | Description                          | Default                             |
| -------------------------------- | ------------------------------------ | ----------------------------------- |
| tower_web_resource_requirements  | Web container resource requirements  | requests: {cpu: 1000m, memory: 2Gi} |
| tower_task_resource_requirements | Task container resource requirements | requests: {cpu: 500m, memory: 1Gi}  |

Example of customization could be:

```yaml
---
spec:
  ...
  tower_web_resource_requirements:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  tower_task_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1000m
      memory: 2Gi
```

#### Assigning AWX pods to specific nodes

You can constrain the AWX pods created by the operator to run on a certain subset of nodes. `tower_node_selector` and `tower_postgres_selector` constrains
the AWX pods to run only on the nodes that match all the specified key/value pairs. `tower_tolerations` and `tower_postgres_tolerations` allow the AWX
pods to be scheduled onto nodes with matching taints.


| Name                           | Description                 | Default |
| -------------------------------| --------------------------- | ------- |
| tower_postgres_image           | Path of the image to pull   | 12      |
| tower_postgres_image_version   | Image version to pull       | 12      |
| tower_node_selector            | AWX pods' nodeSelector      | ''      |
| tower_tolerations              | AWX pods' tolerations       | ''      |
| tower_postgres_selector        | Postgres pods' nodeSelector | ''      |
| tower_postgres_tolerations     | Postgres pods' tolerations  | ''      |

Example of customization could be:

```yaml
---
spec:
  ...
  tower_node_selector: |
    disktype: ssd
    kubernetes.io/arch: amd64
    kubernetes.io/os: linux
  tower_tolerations: |
    - key: "dedicated"
      operator: "Equal"
      value: "AWX"
      effect: "NoSchedule"
  tower_postgres_selector: |
    disktype: ssd
    kubernetes.io/arch: amd64
    kubernetes.io/os: linux
  tower_postgres_tolerations: |
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
| tower_projects_persistence         | Whether or not the /var/lib/projects directory will be persistent                                    |  false         |
| tower_projects_storage_class       | Define the PersistentVolume storage class                                                            |  ''            |
| tower_projects_storage_size        | Define the PersistentVolume size                                                                     |  8Gi           |
| tower_projects_storage_access_mode | Define the PersistentVolume access mode                                                              |  ReadWriteMany |
| tower_projects_existing_claim      | Define an existing PersistentVolumeClaim to use (cannot be combined with `tower_projects_storage_*`) |  ''            |

Example of customization when the `awx-operator` automatically handles the persistent volume could be:

```yaml
---
spec:
  ...
  tower_projects_persistence: true
  tower_projects_storage_class: rook-ceph
  tower_projects_storage_size: 20Gi
```

#### Custom Volume and Volume Mount Options

In a scenario where custom volumes and volume mounts are required to either overwrite defaults or mount configuration files.

| Name                           | Description                                              | Default |
| ------------------------------ | -------------------------------------------------------- | ------- |
| tower_extra_volumes            | Specify extra volumes to add to the application pod      | ''      |
| tower_web_extra_volume_mounts  | Specify volume mounts to be added to Web container       | ''      |
| tower_task_extra_volume_mounts | Specify volume mounts to be added to Task container      | ''      |
| tower_ee_extra_volume_mounts   | Specify volume mounts to be added to Execution container | ''      |

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
      tower_ee_extra_volume_mounts: |
        - name: ansible-cfg
          mountPath: /etc/ansible/ansible.cfg
          subPath: ansible.cfg

      tower_task_extra_volume_mounts: |
        - name: custom-py
          mountPath: /etc/tower/conf.d/custom.py
          subPath: custom.py

      tower_extra_volumes: |
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
| tower_task_extra_env          | Environment variables to be added to Task container      | ''      |
| tower_web_extra_env           | Environment variables to be added to Web container       | ''      |

Example configuration of environment variables

```yaml
  spec:
    tower_task_extra_env: |
      - name: MYCUSTOMVAR
        value: foo
    tower_web_extra_env: |
      - name: MYCUSTOMVAR
        value: foo
```


## Development

### Testing

This Operator includes a [Molecule](https://molecule.readthedocs.io/en/stable/)-based test environment, which can be executed standalone in Docker (e.g. in CI or in a single Docker container anywhere), or inside any kind of Kubernetes cluster (e.g. Minikube).

You need to make sure you have Molecule installed before running the following commands. You can install Molecule with:

```sh
#> pip install 'molecule[docker]'
```

Running `molecule test` sets up a clean environment, builds the operator, runs all configured tests on an example operator instance, then tears down the environment (at least in the case of Docker).

If you want to actively develop the operator, use `molecule converge`, which does everything but tear down the environment at the end.

#### Testing in Docker

```sh
#> molecule test -s test-local
```

This environment is meant for headless testing (e.g. in a CI environment, or when making smaller changes which don't need to be verified through a web interface). It is difficult to test things like AWX's web UI or to connect other applications on your local machine to the services running inside the cluster, since it is inside a Docker container with no static IP address.

#### Testing in Minikube

```sh
#> minikube start --memory 8g --cpus 4
#> minikube addons enable ingress
#> molecule test -s test-minikube
```

[Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) is a more full-featured test environment running inside a full VM on your computer, with an assigned IP address. This makes it easier to test things like NodePort services and Ingress from outside the Kubernetes cluster (e.g. in a browser on your computer).

Once the operator is deployed, you can visit the AWX UI in your browser by following these steps:

  1. Make sure you have an entry like `IP_ADDRESS  example-awx.test` in your `/etc/hosts` file. (Get the IP address with `minikube ip`.)
  2. Visit `http://example-awx.test/` in your browser. (Default admin login is `test`/`changeme`.)

Alternatively, you can also update the service `awx-service` in your namespace to use the type `NodePort` and use following command to get the URL to access your AWX instance:

```sh
#> minikube service <serviceName> -n <namespaceName> --url
```

### Generating a bundle

> :warning: operator-sdk version 0.19.4 is needed to run the following commands

If one has the Operator Lifecycle Manager (OLM) installed, the following steps is the process to generate the bundle that would nicely display in the OLM interface.

At the root of this directory:

1. Build and publish the operator

```
#> operator-sdk build registry.example.com/ansible/awx-operator:mytag
#> podman push registry.example.com/ansible/awx-operator:mytag
```

2. Build and publish the bundle

```
#> podman build . -f bundle.Dockerfile -t registry.example.com/ansible/awx-operator-bundle:mytag
#> podman push registry.example.com/ansible/awx-operator-bundle:mytag
```

3. Build and publish an index with your bundle in it

```
#> opm index add --bundles registry.example.com/ansible/awx-operator-bundle:mytag --tag registry.example.com/ansible/awx-operator-catalog:mytag
#> podman push registry.example.com/ansible/awx-operator-catalog:mytag
```

4. In your Kubernetes create a new CatalogSource pointing to `registry.example.com/ansible/awx-operator-catalog:mytag`

```
---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: <catalogsource-name>
  namespace: <namespace>
spec:
  displayName: 'myoperatorhub'
  image: registry.example.com/ansible/awx-operator-catalog:mytag
  publisher: 'myoperatorhub'
  sourceType: grpc
```

Applying this template will do it. Once the CatalogSource is in a READY state, the bundle should be available on the OperatorHub tab (as part of the custom CatalogSource that just got added)

5. Enjoy

## Release Process

There are a few moving parts to this project:

  1. The Docker image which powers AWX Operator.
  2. The `awx-operator.yaml` Kubernetes manifest file which initially deploys the Operator into a cluster.

Each of these must be appropriately built in preparation for a new tag:

### Verify Functionality

Run the following command inside this directory:

```sh
#> operator-sdk build quay.io/<user>/awx-operator:test
```

Then push the generated image to Docker Hub:

```sh
#> docker push quay.io/<user>/awx-operator:test
```

After it is built, test it on a local cluster:


```sh
#> minikube start --memory 6g --cpus 4
#> minikube addons enable ingress
#> ansible-playbook ansible/deploy-operator.yml -e operator_image=quay.io/<user>/awx-operator -e operator_version=test
#> kubectl create namespace example-awx
#> ansible-playbook ansible/instantiate-awx-deployment.yml -e tower_namespace=example-awx
#> <test everything>
#> minikube delete
```

### Update version

Update the awx-operator version:

  - `ansible/group_vars/all`

Once the version has been updated, run from the root of the repo:

```sh
#> ansible-playbook ansible/chain-operator-files.yml
```

### Commit / Create Release

If everything works, commit the updated version, then [publish a new release](https://github.com/ansible/awx-operator/releases/new) using the same version you used in `ansible/group_vars/all`.

After creating the release, [this GitHub Workflow](https://github.com/ansible/awx-operator/blob/devel/.github/workflows/release.yaml) will run and publish the new image to quay.io.

## Author

This operator was originally built in 2019 by [Jeff Geerling](https://www.jeffgeerling.com) and is now maintained by the Ansible Team
