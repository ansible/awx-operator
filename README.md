# Tower Operator

[![Build Status](https://travis-ci.com/geerlingguy/tower-operator.svg?branch=master)](https://travis-ci.com/geerlingguy/tower-operator)

An [Ansible Tower](https://www.ansible.com/products/tower) operator for Kubernetes built with [Operator SDK](https://github.com/operator-framework/operator-sdk) and Ansible.

## Purpose

There are already OpenShift/Kubernetes installers available for both AWX and Ansible Tower:

  - [AWX on Kubernetes](https://github.com/ansible/awx/blob/devel/INSTALL.md#kubernetes)
  - [Ansible Tower on Kubernetes](https://docs.ansible.com/ansible-tower/latest/html/administration/openshift_configuration.html)

This operator is meant to provide a more Kubernetes-native installation method for Ansible Tower or AWX via a Tower Custom Resource Definition (CRD).

So instead of having to maintain a separate playbook, inventory, and installation configuration for each Tower instance, you can deploy the following Custom Resource (CR) to an existing Kubernetes or OpenShift cluster:

    apiVersion: tower.ansible.com/v1alpha1
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

After a few minutes, your new Tower instance will be accessible at `http://tower.mycompany.com/` (assuming your cluster has an Ingress controller configured).

## Usage

TODO: See [Issue #4](https://github.com/geerlingguy/tower-operator/issues/4).

## Testing

This Operator includes a [Molecule](https://molecule.readthedocs.io/en/stable/)-based test environment, which can be executed standalone in Docker (e.g. in CI or in a single Docker container anywhere), or inside any kind of Kubernetes cluster (e.g. Minikube).

You need to make sure you have Molecule installed before running the following commands. You can install Molecule with:

    pip install 'molecule[docker]

Running `molecule test` sets up a clean environment, builds the operator, runs all configured tests on an example operator instance, then tears down the environment (at least in the case of Docker).

If you want to actively develop the operator, use `molecule converge`, which does everything but tear down the environment at the end.

### Testing in Docker (standalone)

    molecule test -s test-local

This environment is meant for headless testing (e.g. in a CI environment, or when making smaller changes which don't need to be verified through a web interface). It is difficult to test things like Tower's web UI or to connect other applications on your local machine to the services running inside the cluster, since it is inside a Docker container with no static IP address.

### Testing in Minikube

    minikube start --memory 6g --cpus 2
    minikube addons enable ingress
    molecule test -s test-minikube

[Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) is a more full-featured test environment running inside a full VM on your computer, with an assigned IP address. This makes it easier to test things like NodePort services and Ingress from outside the Kubernetes cluster (e.g. in a browser on your computer).

Once the operator is deployed, you can visit the Tower UI in your browser by following these steps:

  1. Make sure you have an entry like `IP_ADDRESS  example-tower.test` in your `/etc/hosts` file. (Get the IP address with `minikube ip`.)
  2. Visit `http://example-tower.test/` in your browser.
