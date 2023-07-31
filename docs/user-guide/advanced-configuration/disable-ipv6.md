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
