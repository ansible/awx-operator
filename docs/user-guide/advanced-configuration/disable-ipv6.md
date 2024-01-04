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
