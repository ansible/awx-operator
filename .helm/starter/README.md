# AWX Operator Helm Chart

This chart installs the AWX Operator resources configured in [this](https://github.com/ansible/awx-operator) repository.

## Getting Started
To configure your AWX resource using this chart, create your own `yaml` values file. The name is up to personal preference since it will explicitly be passed into the helm chart. Helm will merge whatever values you specify in your file with the default `values.yaml`, overriding any settings you've changed while allowing you to fall back on defaults. Because of this functionality, `values.yaml` should not be edited directly.

In your values config, enable `AWX.enabled` and add `AWX.spec` values based on the awx operator's [documentation](https://github.com/ansible/awx-operator/blob/devel/README.md). Consult the docs below for additional functionality.

### Installing
The operator's [helm install](https://github.com/ansible/awx-operator/blob/devel/README.md#helm-install-on-existing-cluster) guide provides key installation instructions.

Example:
```
helm install my-awx-operator awx-operator/awx-operator -n awx --create-namespace -f myvalues.yaml
```

Argument breakdown:
* `-f` passes in the file with your custom values
* `-n` sets the namespace to be installed in
  * This value is accessed by `{{ $.Release.Namespace }}` in the templates
  * Acts as the default namespace for all unspecified resources
* `--create-namespace` specifies that helm should create the namespace before installing

To update an existing installation, use `helm upgrade` instead of `install`. The rest of the syntax remains the same.

## Configuration
The goal of adding helm configurations is to abstract out and simplify the creation of multi-resource configs. The `AWX.spec` field maps directly to the spec configs of the `AWX` resource that the operator provides, which are detailed in the [main README](https://github.com/ansible/awx-operator/blob/devel/README.md). Other sub-config can be added with the goal of simplifying more involved setups that require additional resources to be specified.

These sub-headers aim to be a more intuitive entrypoint into customizing your deployment, and are easier to manage in the long-term. By design, the helm templates will defer to the manually defined specs to avoid configuration conflicts. For example, if `AWX.spec.postgres_configuration_secret` is being used, the `AWX.postgres` settings will not be applied, even if enabled.

### External Postgres
The `AWX.postgres` section simplifies the creation of the external postgres secret. If enabled, the configs provided will automatically be placed in a `postgres-config` secret and linked to the `AWX` resource. For proper secret management, the `AWX.postgres.password` value, and any other sensitive values, can be passed in at the command line rather than specified in code. Use the `--set` argument with `helm install`. Supplying the password this way is not recommended for production use, but may be helpful for initial PoC.


## Values Summary

### AWX
| Value | Description | Default |
|---|---|---|
| `AWX.enabled` | Enable this AWX resource configuration | `false` |
| `AWX.name` | The name of the AWX resource and default prefix for other resources | `"awx"` |
| `AWX.spec` | specs to directly configure the AWX resource | `{}` |
| `AWX.postgres` | configurations for the external postgres secret | - |


# Contributing

## Adding abstracted sections
Where possible, defer to `AWX.spec` configs before applying the abstracted configs to avoid collision. This can be facilitated by the `(hasKey .spec what_i_will_abstract)` check.

## Building and Testing
This chart is built using the Makefile in the [awx-operator repo](https://github.com/ansible/awx-operator). Clone the repo and run `make helm-chart`. This will create the awx-operator chart in the `charts/awx-operator` directory. In this process, the contents of the `.helm/starter` directory will be added to the chart.

## Future Goals
All values under the `AWX` header are focused on configurations that use the operator. Configurations that relate to the Operator itself could be placed under an `Operator` heading, but that may add a layer of complication over current development.


# Chart Publishing

The chart is currently hosted on the gh-pages branch of the repo. During the release pipeline, the `index.yaml` stored in that branch is generated with helm chart entries from all valid tags. We are currently unable to use the `chart-releaser` pipeline due to the fact that the complete helm chart is not committed to the repo and is instead built during the release process. Therefore, the cr action is unable to compare against previous versions.

Instead of CR, we use `helm repo index` to generate an index from all locally pulled chart versions. Since we build from scratch every time, the timestamps of all entries will be updated. This could be improved by using yq or something similar to detect which tags are already in the index.yaml file, and only merge in tags that are not present.

Not using CR could be addressed in the future by keeping the chart built as a part of releases, as long as CR compares the chart to previous release packages rather than previous commits. If the latter is the case, then we would not have the necessary history for comparison.


