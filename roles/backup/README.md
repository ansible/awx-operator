Role Name
=========

The purpose of this role is to create a backup of your AWX deployment.  This includes:
  - backup of the postgresql database
  - secret_key
  - custom user config files
  - manual projects


Requirements
------------

This role assumes you are authenticated with an Openshift or Kubernetes cluster which:
  - The awx-operator has been deployed to
  - AWX is deployed to via the operator


Usage
----------------

Then create a file named `backup-awx.yml` with the following contents:

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: Backup
metadata:
  name: awx
  namespace: my-namespace
```

> The metadata.name you provide, is the name of the AWX deployment you intend to backup from (in case you have multiple in the same namespace).

Finally, use `kubectl` to create the backup object in your cluster:

```bash
#> kubectl apply -f backup-awx.yml
```

The resulting pvc will contain a backup tar that can be used to restore to a new deployment. Future backups will also be stored in separate tars on the same pvc.


Role Variables
--------------

A custom, pre-created pvc can be used by setting the following variables.  

```
tower_backup_pvc: 'awx-backup-volume-claim'
```

> If no pvc or storage class is provided, the cluster's default storage class will be used to create the pvc.

This role will automatically create a pvc using a Storage Class if provided:

```
tower_backup_storage_class: 'standard'
tower_backup_size: '20Gi'
```

If a custom postgres configuration secret was used when deploying AWX, it must be set:

```
tower_postgres_configuration_secret: 'awx-postgres-configuration'
```


Testing
----------------

You can test this role directly by creating and running the following playbook with the appropriate variables:

```
---
- name: Backup Tower
  hosts: localhost
  gather_facts: false
  roles:
    - backup
```

License
-------

MIT
