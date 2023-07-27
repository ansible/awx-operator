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

NOTE:  we are in the process of moving this readme into official docs in the /docs folder. Please go there to find additional sections during this interim move phase.

* [AWX Operator](#awx-operator)
* [Table of Contents](#table-of-contents)
   * [Usage](#usage)
      * [Disable IPV6](#disable-ipv6)
      * [Add Execution Nodes](#adding-execution-nodes)
          * [Custom Receptor CA](#custom-receptor-ca)
   * [Contributing](#contributing)
   * [Release Process](#release-process)
   * [Author](#author)
   * [Code of Conduct](#code-of-conduct)
   * [Get Involved](#get-involved)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

<!--te-->


### Disable IPV6
Starting with AWX Operator release 0.24.0,[IPV6 was enabled in ngnix configuration](https://github.com/ansible/awx-operator/pull/950) which causes
upgrades and installs to fail in environments where IPv6 is not allowed. Starting in 1.1.1 release, you can set the `ipv6_disabled` flag on the AWX
spec. If you need to use an AWX operator version between 0.24.0 and 1.1.1 in an IPv6 disabled environment, it is suggested to enabled ipv6 on worker
nodes.

In order to disable ipv6 on ngnix configuration (awx-web container), add following to the AWX spec.

The following variables are customizable 

| Name          | Description            | Default |
| ------------- | ---------------------- | ------- |
| ipv6_disabled | Flag to disable ipv6   | false   |

```yaml
spec:
  ipv6_disabled: true
```

### Adding Execution Nodes
Starting with AWX Operator v0.30.0 and AWX v21.7.0, standalone execution nodes can be added to your deployments.
See [AWX execution nodes docs](https://github.com/ansible/awx/blob/devel/docs/execution_nodes.md) for information about this feature.

#### Custom Receptor CA
The control nodes on the K8S cluster will communicate with execution nodes via mutual TLS TCP connections, running via Receptor.
Execution nodes will verify incoming connections by ensuring the x509 certificate was issued by a trusted Certificate Authority (CA).

A user may wish to provide their own CA for this validation. If no CA is provided, AWX Operator will automatically generate one using OpenSSL.

Given custom `ca.crt` and `ca.key` stored locally, run the following,

```bash
kubectl create secret tls awx-demo-receptor-ca \
   --cert=/path/to/ca.crt --key=/path/to/ca.key
```

The secret should be named `{AWX Custom Resource name}-receptor-ca`. In the above the AWX CR name is "awx-demo". Please replace "awx-demo" with your AWX Custom Resource name.

If this secret is created after AWX is deployed, run the following to restart the deployment,

```bash
kubectl rollout restart deployment awx-demo
```

**Important Note**, changing the receptor CA will break connections to any existing execution nodes. These nodes will enter an `unavailable` state, and jobs will not be able to run on them. Users will need to download and re-run the install bundle for each execution node. This will replace the TLS certificate files with those signed by the new CA. The execution nodes should then appear in a `ready` state after a few minutes.

## Contributing

Please visit [our contributing guidelines](https://github.com/ansible/awx-operator/blob/devel/CONTRIBUTING.md).


## Release Process

The first step is to create a draft release. Typically this will happen in the [Stage Release](https://github.com/ansible/awx/blob/devel/.github/workflows/stage.yml) workflow for AWX and you don't need to do it as a separate step.

If you need to do an independent release of the operator, you can run the [Stage Release](https://github.com/ansible/awx-operator/blob/devel/.github/workflows/stage.yml) in the awx-operator repo. Both of these workflows will run smoke tests, so there is no need to do this manually.

After the draft release is created, publish it and the [Promote AWX Operator image](https://github.com/ansible/awx-operator/blob/devel/.github/workflows/promote.yaml) will run, which will:

- Publish image to Quay
- Release Helm chart

## Author

This operator was originally built in 2019 by [Jeff Geerling](https://www.jeffgeerling.com) and is now maintained by the Ansible Team

## Code of Conduct

We ask all of our community members and contributors to adhere to the [Ansible code of conduct](http://docs.ansible.com/ansible/latest/community/code_of_conduct.html). If you have questions or need assistance, please reach out to our community team at [codeofconduct@ansible.com](mailto:codeofconduct@ansible.com)

## Get Involved

We welcome your feedback and ideas. The AWX operator uses the same mailing list and IRC channel as AWX itself. Here's how to reach us with feedback and questions:

- Join the `#ansible-awx` channel on irc.libera.chat
- Join the [mailing list](https://groups.google.com/forum/#!forum/awx-project)
