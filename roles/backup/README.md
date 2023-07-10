Backup Role
=========

The purpose of this role is to create a backup of your AWX deployment which includes:
  - custom deployment specific values in the spec section of the AWX custom resource object
  - backup of the postgresql database
  - secret_key, admin_password, and broadcast_websocket secrets
  - database configuration

Requirements
------------

This role assumes you are authenticated with an Openshift or Kubernetes cluster:
  - The awx-operator has been deployed to the cluster
  - AWX is deployed to via the operator


Usage
----------------

Then create a file named `backup-awx.yml` with the following contents:

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWXBackup
metadata:
  name: awxbackup-2021-04-22
  namespace: my-namespace
spec:
  deployment_name: mytower
```

Note that the `deployment_name` above is the name of the AWX deployment you intend to backup from.  The namespace above is the one containing the AWX deployment that will be backed up.

Finally, use `kubectl` to create the backup object in your cluster:

```bash
$ kubectl apply -f backup-awx.yml
```

The resulting pvc will contain a backup tar that can be used to restore to a new deployment. Future backups will also be stored in separate tars on the same pvc.


Role Variables
--------------

A custom, pre-created pvc can be used by setting the following variables.

```
backup_pvc: 'awx-backup-volume-claim'
```

> If no pvc or storage class is provided, the cluster's default storage class will be used to create the pvc.

This role will automatically create a pvc using a Storage Class if provided:

```
backup_storage_class: 'standard'
backup_storage_requirements: '20Gi'
```

By default, the backup pvc will be created in the same namespace the awxbackup object is created in.  If you want your backup to be stored
in a specific namespace, you can do so by specifying `backup_pvc_namespace`.  Keep in mind that you will
need to provide the same namespace when restoring.

```
backup_pvc_namespace: 'custom-namespace'
```
The backup pvc will be created in the same namespace the awxbackup object is created in.

If a custom postgres configuration secret was used when deploying AWX, it will automatically be used by the backup role.
To check the name of this secret, look at the postgresConfigurationSecret status on your AWX object.

The postgresql pod for the old deployment is used when backing up data to the new postgresql pod.  If your postgresql pod has a custom label,
you can pass that via the `postgres_label_selector` variable to make sure the postgresql pod can be found.

It is also possible to tie the lifetime of the backup files to that of the AWXBackup resource object. To do that you can set the
`clean_backup_on_delete` value to true. This will delete the `backupDirectory` on the pvc associated with the AWXBackup object deleted.

```
clean_backup_on_delete: true
```

Variable to define Pull policy.You can pass other options like `Always`, `always`, `Never`, `never`, `IfNotPresent`, `ifnotpresent`.

```
image_pull_policy: 'IfNotPresent'
```

Variable to define resources limits and request for backup CR.
```
backup_resource_requirements:
  limits:
    cpu: "1000m"
    memory: "4096Mi"
  requests:
    cpu: "25m"
    memory: "32Mi"
```

To customize the pg_dump command that will be executed on a backup use the `pg_dump_suffix` variable. This variable will append your provided pg_dump parameters to the end of the 'standard' command. For example to exclude the data from 'main_jobevent' and 'main_job' to decrease the size of the backup use:

```
pg_dump_suffix: "--exclude-table-data 'main_jobevent*' --exclude-table-data 'main_job'"
```

Testing
----------------

You can test this role directly by creating and running the following playbook with the appropriate variables:

```
---
- name: Backup AWX
  hosts: localhost
  gather_facts: false
  roles:
    - backup
```

License
-------

MIT
