Role Name
=========

The purpose of this role is to restore your AWX deployment from an existing PVC backup. The backup should include:
  - backup of the postgresql database
  - secrets, included the secret_key.  
  - AWX custom resource object with deployment specific settings


Requirements
------------

This role assumes you are authenticated with an Openshift or Kubernetes cluster which:
  - The awx-operator has been deployed to
  - AWX is deployed to via the operator


Usage
----------------

Then create a file named `restore-awx.yml` with the following contents:

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWXRestore
metadata:
  name: restore1
  namespace: my-namespace
spec:
  tower_name: mytower
  tower_backup_pvc: awxbackup1-backup-claim
  tower_backup_dir: /backups/tower-openshift-backup-2021-04-02-03:25:08
```

Note that the `tower_name` above is the name of the AWX deployment you intend to create and restore to.  

The namespace specified is the namespace the resulting AWX deployment will be in.  The namespace you specified must be pre-created.  

```
kubectl create ns my-namespace
```

Finally, use `kubectl` to create the restore object in your cluster:

```bash
#> kubectl apply -f restore-awx.yml
```

This will create a new deployment and restore your backup to it.  


Role Variables
--------------

The name of the backup directory can be found as a status on your AWXBackup object.  This can be found in your cluster's console, or with the client as shown below.  

```bash
$ kubectl get awxbackup awxbackup1 -o jsonpath="{.items[0].status.towerBackupDirectory}"
/backups/tower-openshift-backup-2021-04-02-03:25:08
```

```
tower_backup_dir: '/backups/tower-openshift-backup-2021-04-02-03:25:08'
```


The name of the PVC can also be found by looking at the backup object.  

```bash
$ kubectl get awxbackup awxbackup1 -o jsonpath="{.items[0].status.towerBackupClaim}"
awx-backup-volume-claim
```

```
tower_backup_pvc: 'awx-backup-volume-claim'
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
- name: Restore AWX
  hosts: localhost
  gather_facts: false
  roles:
    - restore
```

License
-------

MIT
