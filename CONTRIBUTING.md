# AWX-Operator Contributing Guidelines

Hi there! We're excited to have you as a contributor.

Have questions about this document or anything not covered here? Please file a new at [https://github.com/ansible/awx-operator/issues](https://github.com/ansible/awx-operator/issues).

## Table of contents

- [AWX-Operator Contributing Guidelines](#awx-operator-contributing-guidelines)
  - [Table of contents](#table-of-contents)
  - [Things to know prior to submitting code](#things-to-know-prior-to-submitting-code)
  - [Submmiting your work](#submmiting-your-work)
  - [Testing](#testing)
      - [Testing in Kind](#testing-in-kind)
      - [Testing in Minikube](#testing-in-minikube)
  - [Generating a bundle](#generating-a-bundle)
  - [Reporting Issues](#reporting-issues)


## Things to know prior to submitting code

- All code submissions are done through pull requests against the `devel` branch.
- All PRs must have a single commit. Make sure to `squash` any changes into a single commit.
- Take care to make sure no merge commits are in the submission, and use `git rebase` vs `git merge` for this reason.
- If collaborating with someone else on the same branch, consider using `--force-with-lease` instead of `--force`. This will prevent you from accidentally overwriting commits pushed by someone else. For more information, see https://git-scm.com/docs/git-push#git-push---force-with-leaseltrefnamegt
- We ask all of our community members and contributors to adhere to the [Ansible code of conduct](http://docs.ansible.com/ansible/latest/community/code_of_conduct.html). If you have questions, or need assistance, please reach out to our community team at [codeofconduct@ansible.com](mailto:codeofconduct@ansible.com)


## Submmiting your work
1. From your fork `devel` branch, create a new branch to stage your changes.
```sh
#> git checkout -b <branch-name>
```
2. Make your changes.
3. Test your changes according described on the Testing section.
4. If everything looks correct, commit your changes.
```sh
#> git add <FILES>
#> git commit -m "My message here"
```
5. Create your [pull request](https://github.com/ansible/awx-operator/pulls)

**Note**: If you have multiple commits, make sure to `squash` your commits into a single commit which will facilitate our release process.



## Testing

This Operator includes a [Molecule](https://ansible.readthedocs.io/projects/molecule/)-based test environment, which can be executed standalone in Docker (e.g. in CI or in a single Docker container anywhere), or inside any kind of Kubernetes cluster (e.g. Minikube).

You need to make sure you have Molecule installed before running the following commands. You can install Molecule with:

```sh
#> python -m pip install molecule-plugins[docker]
```

Running `molecule test` sets up a clean environment, builds the operator, runs all configured tests on an example operator instance, then tears down the environment (at least in the case of Docker).

If you want to actively develop the operator, use `molecule converge`, which does everything but tear down the environment at the end.

#### Testing in Kind

Testing with a kind cluster is the recommended way to test the awx-operator locally. First, you need to install kind if you haven't already. Please see these docs for setting that up:
* https://kind.sigs.k8s.io/docs/user/quick-start/

To run the tests, from the root of your checkout, run the following command:

```sh
#> molecule test -s kind
```

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

## Generating a bundle

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


## Reporting Issues

We welcome your feedback, and encourage you to file an issue when you run into a problem.
