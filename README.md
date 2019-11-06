# Tower Operator

[![Build Status](https://travis-ci.com/geerlingguy/tower-operator.svg?branch=master)](https://travis-ci.com/geerlingguy/tower-operator)

An [Ansible Tower](https://www.ansible.com/products/tower) operator for Kubernetes built with [Operator SDK](https://github.com/operator-framework/operator-sdk) and Ansible.

## Testing

This Operator includes a molecule-based test framework, which can be executed standalone in Docker (e.g. in CI or in a single Docker container anywhere), or inside any kind of Kubernetes cluster (e.g. Minikube).

### Testing in Docker (standalone)

  1. `molecule converge -s test-local`

### Testing in Minikube

  1. `minikube start`
  1. `molecule converge -s test-minikube`
