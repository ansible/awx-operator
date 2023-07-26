#### Redis container capabilities

Depending on your kubernetes cluster and settings you might need to grant some capabilities to the redis container so it can start. Set the `redis_capabilities` option so the capabilities are added in the deployment.

```yaml
---
spec:
  ...
  redis_capabilities:
    - CHOWN
    - SETUID
    - SETGID
```
