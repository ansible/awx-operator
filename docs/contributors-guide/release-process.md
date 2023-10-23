## Release Process

The first step is to create a draft release. Typically this will happen in the [Stage Release](https://github.com/ansible/awx/blob/devel/.github/workflows/stage.yml) workflow for AWX and you don't need to do it as a separate step.

If you need to do an independent release of the operator, you can run the [Stage Release](https://github.com/ansible/awx-operator/blob/devel/.github/workflows/stage.yml) in the awx-operator repo. Both of these workflows will run smoke tests, so there is no need to do this manually.

After the draft release is created, publish it and the [Promote AWX Operator image](https://github.com/ansible/awx-operator/blob/devel/.github/workflows/promote.yaml) will run, which will:

- Publish image to Quay
- Release Helm chart

After the GHA is complete, the final step is to run the [publish-to-operator-hub.sh](https://github.com/ansible/awx-operator/blob/devel/hack/publish-to-operator-hub.sh) script, which will create a PR in the following repos to add the new awx-operator bundle version to OperatorHub:
* https://github.com/k8s-operatorhub/community-operators (community operator index)
* https://github.com/redhat-openshift-ecosystem/community-operators-prod (operator index shipped with Openshift)

The usage is documented in the script itself, but here is an example of how you would use the script to publish the 2.5.3 awx-opeator bundle to OperatorHub.
Note that you need to specify the version being released, as well as the previous version. This is because the bundle has a pointer to the previous version that is it being upgrade from. This is used by OLM to create a dependency graph.

```bash
$ VERSION=2.5.3 PREV_VERSION=2.5.2 ./publish-operator.sh
```

> Note: There are some quirks with running this on OS X that still need to be fixed, but the script runs smoothly on linux.

As soon as CI completes successfully, the PR's will be auto-merged. Please remember to monitor those PR's to make sure that CI passes, sometimes it needs a retry.
