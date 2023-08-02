# AWX Operator

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Build Status](https://github.com/ansible/awx-operator/workflows/CI/badge.svg?event=push)](https://github.com/ansible/awx-operator/actions)
[![Code of Conduct](https://img.shields.io/badge/code%20of%20conduct-Ansible-yellow.svg)](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html) 
[![AWX Mailing List](https://img.shields.io/badge/mailing%20list-AWX-orange.svg)](https://groups.google.com/g/awx-project)
[![IRC Chat - #ansible-awx](https://img.shields.io/badge/IRC-%23ansible--awx-blueviolet.svg)](https://libera.chat)

An [Ansible AWX](https://github.com/ansible/awx) operator for Kubernetes built with [Operator SDK](https://github.com/operator-framework/operator-sdk) and Ansible.

<!-- Regenerate this table of contents using https://github.com/ekalinin/github-markdown-toc -->
<!-- gh-md-toc --insert README.md -->
<!--ts-->

**Note**: We are in the process of moving this readme into official docs in the /docs folder. Please go there to find additional sections during this interim move phase.


Table of Contents
=================

- [AWX Operator](#awx-operator)
- [Table of Contents](#table-of-contents)
  - [Install and Configuration](#install-and-configuration)
  - [Contributing](#contributing)
  - [Release Process](#release-process)
  - [Author](#author)
  - [Code of Conduct](#code-of-conduct)
  - [Get Involved](#get-involved)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

<!--te-->



## Install and Configuration

All of our usage and configuration docs are nested in the `docs/` directory. Below is a Table of Contents for those.

- Introduction
  - [Introduction](./docs/introduction.md)
- Contributors Guide
  - [Code of Conduct](./docs/code-of-conduct.md)
  - [Get Involved](./docs/get-involved.md)
  - [Contributing](./docs/contributing.md)
  - [Release Process](./docs/release-process.md)
  - [Authors](./docs/author.md)
- Installation
  - [Basic Install](./docs/basic-install.md)
  - [Creating a Minikube cluster for testing](./docs/creating-a-minikube-cluster-for-testing.md)
  - [Installation](./docs/installation.md)
  - [Helm Install](./docs/helm-install-on-existing-cluster.md)
- [Migration](./docs/migration.md)
- [Uninstall](./docs/uninstall.md)
- User Guide
  - [Admin User Configuration](./docs/admin-user-account-configuration.md)
  - [Database Configuration](./docs/database-configuration.md)
  - [Network and TLS Configuration](./docs/network-and-tls-configuration.md)
  - Advanced Configuration
    - [No Log](./docs/no-log.md)
    - [Deploy a Specific Version of AWX](./docs/deploying-a-specific-version-of-awx.md)
    - [Resource Requirements](./docs/containers-resource-requirements.md)
    - [Extra Settings](./docs/extra-settings.md)
    - [Environment Variables](./docs/exporting-environment-variables-to-containers.md)
    - [Custom Labels](./docs/labeling-operator-managed-objects.md)
    - [Custom Volumes](./docs/custom-volume-and-volume-mount-options.md)
    - [Scaling Deployments](./docs/scaling-the-web-and-task-pods-independently.md)
    - [Auto Update Upon Operator Upgrade](./docs/auto-upgrade.md)
    - [Termination Grace Period](./docs/pods-termination-grace-period.md)
    - [Node Selector for Deployments](./docs/assigning-awx-pods-to-specific-nodes.md)
    - [Default EE from Private Registries](./docs/default-execution-environments-from-private-registries.md)
    - [CSRF Cookie Secure](./docs/csrf-cookie-secure-setting.md)
    - [Disable IPv6](./docs/disable-ipv6.md)
    - [LDAP](./docs/enabling-ldap-integration-at-awx-bootstrap.md)
    - [Priority Clases](./docs/priority-classes.md)
    - [Priveleged Tasks](./docs/privileged-tasks.md)
    - [Redis Container Capabilities](./docs/redis-container-capabilities.md)
    - [Trusting a Custom Certificate Authority](./docs/trusting-a-custom-certificate-authority.md)
    - [Service Account](./docs/service-account.md)
    - [Persisting the Projects Directory](./docs/persisting-projects-directory.md)
- Troubleshooting
  - [General Debugging](./docs/debugging.md)


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
