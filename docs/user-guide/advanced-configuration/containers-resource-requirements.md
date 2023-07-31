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

| Name                       | Description                                      | Default                              |
| -------------------------- | ------------------------------------------------ | ------------------------------------ |
| web_resource_requirements  | Web container resource requirements              | requests: {cpu: 100m, memory: 128Mi} |
| task_resource_requirements | Task container resource requirements             | requests: {cpu: 100m, memory: 128Mi} |
| ee_resource_requirements   | EE control plane container resource requirements | requests: {cpu: 100m, memory: 128Mi} |

Example of customization could be:

```yaml
---
spec:
  ...
  web_resource_requirements:
    requests:
      cpu: 250m
      memory: 2Gi
      ephemeral-storage: 100M
    limits:
      cpu: 1000m
      memory: 4Gi
      ephemeral-storage: 500M
  task_resource_requirements:
    requests:
      cpu: 250m
      memory: 1Gi
      ephemeral-storage: 100M
    limits:
      cpu: 2000m
      memory: 2Gi
      ephemeral-storage: 500M
  ee_resource_requirements:
    requests:
      cpu: 250m
      memory: 100Mi
      ephemeral-storage: 100M
    limits:
      cpu: 500m
      memory: 2Gi
      ephemeral-storage: 500M
```
