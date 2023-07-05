#### Privileged Tasks

Depending on the type of tasks that you'll be running, you may find that you need the task pod to run as `privileged`. This can open yourself up to a variety of security concerns, so you should be aware (and verify that you have the privileges) to do this if necessary. In order to toggle this feature, you can add the following to your custom resource:

```yaml
---
spec:
  ...
  task_privileged: true
```

If you are attempting to do this on an OpenShift cluster, you will need to grant the `awx` ServiceAccount the `privileged` SCC, which can be done with:

```
$ oc adm policy add-scc-to-user privileged -z awx
```

Again, this is the most relaxed SCC that is provided by OpenShift, so be sure to familiarize yourself with the security concerns that accompany this action.
