#### Persisting Projects Directory

In cases which you want to persist the `/var/lib/projects` directory, there are few variables that are customizable for the `awx-operator`.

| Name                         | Description                                                                                    | Default       |
| ---------------------------- | ---------------------------------------------------------------------------------------------- | ------------- |
| projects_persistence         | Whether or not the /var/lib/projects directory will be persistent                              | false         |
| projects_storage_class       | Define the PersistentVolume storage class                                                      | ''            |
| projects_storage_size        | Define the PersistentVolume size                                                               | 8Gi           |
| projects_storage_access_mode | Define the PersistentVolume access mode                                                        | ReadWriteMany |
| projects_existing_claim      | Define an existing PersistentVolumeClaim to use (cannot be combined with `projects_storage_*`) | ''            |

Example of customization when the `awx-operator` automatically handles the persistent volume could be:

```yaml
---
spec:
  ...
  projects_persistence: true
  projects_storage_class: rook-ceph
  projects_storage_size: 20Gi
```
