### Uninstall ###

To uninstall an AWX deployment instance, you basically need to remove the AWX kind related to that instance. For example, to delete an AWX instance named awx-demo, you would do:

```
$ kubectl delete awx awx-demo
awx.awx.ansible.com "awx-demo" deleted
```

Deleting an AWX instance will remove all related deployments and statefulsets, however, persistent volumes and secrets will remain. To enforce secrets also getting removed, you can use `garbage_collect_secrets: true`.

**Note**: If you ever intend to recover an AWX from an existing database you will need a copy of the secrets in order to perform a successful recovery.
