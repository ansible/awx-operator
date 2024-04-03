#### Containers HostAliases Requirements

Sometimes you might need to use [HostAliases](https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/) in web/task containers.

| Name         | Description           | Default |
| ------------ | --------------------- | ------- |
| host_aliases | A list of HostAliases | None    |

Example of customization could be:

```yaml
---
spec:
  ...
  host_aliases:
    - ip: <name-of-your-ip>
      hostnames:
        - <name-of-your-domain>
```

#### Containers Resource Requirements

The resource requirements for both, the task and the web containers are configurable - both the lower end (requests) and the upper end (limits).

| Name                                 | Description                                                  | Default                              |
| ------------------------------------ | ------------------------------------------------------------ | ------------------------------------ |
| web_resource_requirements            | Web container resource requirements                          | requests: {cpu: 100m, memory: 128Mi} |
| task_resource_requirements           | Task container resource requirements                         | requests: {cpu: 100m, memory: 128Mi} |
| ee_resource_requirements             | EE control plane container resource requirements             | requests: {cpu: 50m, memory: 64Mi} |
| redis_resource_requirements          | Redis container resource requirements                        | requests: {cpu: 100m, memory: 128Mi} |
| postgres_resource_requirements       | Postgres container (and initContainer) resource requirements | requests: {cpu: 10m, memory: 64Mi}   |
| rsyslog_resource_requirements        | Rsyslog container resource requirements                      | requests: {cpu: 100m, memory: 128Mi} |
| init_container_resource_requirements | Init Container resource requirements                         | requests: {cpu: 100m, memory: 128Mi} |


Example of customization could be:

```yaml
---
spec:
  ...

  task_resource_requirements:
    requests:
      cpu: 100m
      memory: 128Mi
      ephemeral-storage: 100M
    limits:
      cpu: 2000m
      memory: 4Gi
      ephemeral-storage: 500M
  web_resource_requirements:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 1000m
      memory: 4Gi
  ee_resource_requirements:
    requests:
      cpu: 100m
      memory: 64Mi
    limits:
      cpu: 1000m
      memory: 4Gi
  redis_resource_requirements:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 1000m
      memory: 4Gi
  rsyslog_resource_requirements:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 1000m
      memory: 2Gi
  init_container_resource_requirements:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 1000m
      memory: 2Gi
```


#### Limits and ResourceQuotas

If the cluster you are deploying in has a ResoruceQuota, you will need to configure resource limits for all of the pods deployed in that cluster. This can be done for AWX pods on the AWX spec in the manner shown above.

There is an example you can use in [`awx_v1beta1_awx_resource_limits.yaml`](https://raw.githubusercontent.com/ansible/awx-operator/devel/config/samples/awx_v1beta1_awx_resource_limits.yaml).
