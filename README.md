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

NOTE:  we are in the process of moving this readme into official docs in the /docs folder. Please go there to find additional sections during this interim move phase.


Table of Contents
=================

* [AWX Operator](#awx-operator)
   * [Contributing](#contributing)
   * [Release Process](#release-process)
   * [Author](#author)
   * [Code of Conduct](#code-of-conduct)
   * [Get Involved](#get-involved)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

<!--te-->



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
