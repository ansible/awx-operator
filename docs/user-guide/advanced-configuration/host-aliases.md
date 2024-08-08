# HostAliases

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
