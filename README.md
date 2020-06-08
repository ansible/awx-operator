# Ansible Tower/AWX Operator

[![Build Status](https://travis-ci.com/geerlingguy/tower-operator.svg?branch=master)](https://travis-ci.com/geerlingguy/tower-operator)

An [Ansible Tower](https://www.ansible.com/products/tower) operator for Kubernetes built with [Operator SDK](https://github.com/operator-framework/operator-sdk) and Ansible.

Also configurable to run the open source [AWX](https://github.com/ansible/awx) instead of Tower (helpful for certain use cases where a license requirement is not warranted, like CI environments).

## Purpose

There are already official OpenShift/Kubernetes installers available for both AWX and Ansible Tower:

  - [AWX on Kubernetes](https://github.com/ansible/awx/blob/devel/INSTALL.md#kubernetes)
  - [Ansible Tower on Kubernetes](https://docs.ansible.com/ansible-tower/latest/html/administration/openshift_configuration.html)

This operator is meant to provide a more Kubernetes-native installation method for Ansible Tower or AWX via a Tower Custom Resource Definition (CRD).

Note that the operator is not supported by Red Hat, and is in alpha status. Long-term, it will hopefully become a supported installation method, and be listed on OperatorHub.io. But for now, use it at your own risk!

## Usage

This Kubernetes Operator is meant to be deployed in your Kubernetes cluster(s) and can manage one or more Tower or AWX instances in any namespace.

First you need to deploy Tower Operator into your cluster:

    kubectl apply -f https://raw.githubusercontent.com/geerlingguy/tower-operator/master/deploy/tower-operator.yaml

Then you can create instances of Tower, for example:

  1. Make sure the namespace you're deploying into already exists (e.g. `kubectl create namespace ansible-tower`).
  1. Create a file named `my-tower.yml` with the following contents:

     ```
     ---
     apiVersion: tower.ansible.com/v1beta1
     kind: Tower
     metadata:
       name: tower
       namespace: ansible-tower
     spec:
       tower_hostname: tower.mycompany.com
       tower_secret_key: aabbcc
       
       tower_admin_user: test
       tower_admin_email: test@example.com
       tower_admin_password: changeme
     ```

  1. Use `kubectl` to create the mcrouter instance in your cluster:

     ```
     kubectl apply -f my-tower.yml
     ```

After a few minutes, your new Tower instance will be accessible at `http://tower.mycompany.com/` (assuming your cluster has an Ingress controller configured). Log in using the `tower_admin_` credentials configured in the `spec`, and supply a valid license to begin using Tower.

### Red Hat Registry Authentication

To deploy Ansible Tower, images are pulled from the Red Hat Registry. Your Kubernetes or OpenShift cluster will have to have [Authentication Enabled for the Red Hat Registry](https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/configuring_clusters/install-config-configuring-red-hat-registry) for this to work, otherwise the Tower image will not be pulled.

If you deploy Ansible AWX, images are available from public registries, so no authentication is required.

### Deploy AWX instead of Tower

If you would like to deploy AWX (the open source upstream of Tower) into your cluster instead of Tower, override the default variables in the Tower `spec` for the `tower_task_image` and `tower_web_image`, so the AWX container images are used instead, and set the `deployment_type` to ``awx`:

    ---
    spec:
      ...
      deployment_type: awx
      tower_task_image: ansible/awx_task:11.2.0
      tower_web_image: ansible/awx_web:11.2.0

### Ingress Types

Depending on the cluster that you're running on, you may wish to use an `Ingress` to access your tower or you may wish to use a `Route` to access your tower. To toggle between these two options, you can add the following to your Tower custom resource:

    ---
    spec:
      ...
      tower_ingress_type: Route

OR

    ---
    spec:
      ...
      tower_ingress_type: Ingress

By default, no ingress/route is deployed as the default is set to `none`.

### Privileged Tasks

Depending on the type of tasks that you'll be running, you may find that you need the tower task pod to run as `privileged`. This can open yourself up to a variety of security concerns, so you should be aware (and verify that you have the privileges) to do this if necessary. In order to toggle this feature, you can add the following to your Tower custom resource:

    ---
    spec:
      ...
      tower_task_privileged: true

If you are attempting to do this on an OpenShift cluster, you will need to grant the `tower` ServiceAccount the `privileged` SCC, which can be done with:

    oc adm policy add-scc-to-user privileged -z tower

Again, this is the most relaxed SCC that is provided by OpenShift, so be sure to familiarize yourself with the security concerns that accompany this action.


### Persistent storage for Postgres

If you need to use a specific storage class for Postgres' storage, specify `tower_postgres_storage_class` in your Tower spec:

    ---
    spec:
      ...
      tower_postgres_storage_class: fast-ssd

If it's not specified, Postgres will store it's data on a volume using the default storage class for your cluster.

## Development

### Testing

This Operator includes a [Molecule](https://molecule.readthedocs.io/en/stable/)-based test environment, which can be executed standalone in Docker (e.g. in CI or in a single Docker container anywhere), or inside any kind of Kubernetes cluster (e.g. Minikube).

You need to make sure you have Molecule installed before running the following commands. You can install Molecule with:

    pip install 'molecule[docker]'

Running `molecule test` sets up a clean environment, builds the operator, runs all configured tests on an example operator instance, then tears down the environment (at least in the case of Docker).

If you want to actively develop the operator, use `molecule converge`, which does everything but tear down the environment at the end.

#### Testing in Docker (standalone)

    molecule test -s test-local

This environment is meant for headless testing (e.g. in a CI environment, or when making smaller changes which don't need to be verified through a web interface). It is difficult to test things like Tower's web UI or to connect other applications on your local machine to the services running inside the cluster, since it is inside a Docker container with no static IP address.

#### Testing in Minikube

    minikube start --memory 8g --cpus 4
    minikube addons enable ingress
    molecule test -s test-minikube

[Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) is a more full-featured test environment running inside a full VM on your computer, with an assigned IP address. This makes it easier to test things like NodePort services and Ingress from outside the Kubernetes cluster (e.g. in a browser on your computer).

Once the operator is deployed, you can visit the Tower UI in your browser by following these steps:

  1. Make sure you have an entry like `IP_ADDRESS  example-tower.test` in your `/etc/hosts` file. (Get the IP address with `minikube ip`.)
  2. Visit `http://example-tower.test/` in your browser. (Default admin login is `test`/`changeme`.)

### Release Process

There are a few moving parts to this project:

  1. The Docker image which powers Tower Operator.
  2. The `tower-operator.yaml` Kubernetes manifest file which initially deploys the Operator into a cluster.

Each of these must be appropriately built in preparation for a new tag:

#### Build a new release of the Operator for Docker Hub

Run the following command inside this directory:

    operator-sdk build geerlingguy/tower-operator:0.4.0

Then push the generated image to Docker Hub:

    docker push geerlingguy/tower-operator:0.4.0

#### Build a new version of the `tower-operator.yaml` file

Update the tower-operator version in two places:

  1. `deploy/tower-operator.yaml`: in the `ansible` and `operator` container definitions in the `tower-operator` Deployment.
  2. `build/chain-operator-files.yml`: the `operator_image` variable.

Once the versions are updated, run the playbook in the `build/` directory:

    ansible-playbook chain-operator-files.yml

After it is built, test it on a local cluster:

    minikube start --memory 6g --cpus 4
    minikube addons enable ingress
    kubectl apply -f deploy/tower-operator.yaml
    kubectl create namespace example-tower
    kubectl apply -f deploy/crds/tower_v1beta1_tower_cr_awx.yaml
    <test everything>
    minikube delete

If everything works, commit the updated version, then tag a new repository release with the same tag as the Docker image pushed earlier.

## Author

This operator was built in 2019 by [Jeff Geerling](https://www.jeffgeerling.com), author of [Ansible for DevOps](https://www.ansiblefordevops.com) and [Ansible for Kubernetes](https://www.ansibleforkubernetes.com).
