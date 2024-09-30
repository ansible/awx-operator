Restore Role
=========

The purpose of this role is to restore your AWX deployment from an existing PVC backup. The backup includes:
  - custom deployment specific values in the spec section of the AWX custom resource object
  - backup of the postgresql database
  - secret_key, admin_password, and broadcast_websocket secrets
  - database configuration


The AWXRestore is designed to cover following two scenarios:

A) Restoring from the exsiting AWXBackup CR
the backup_name param is for this scenario
<br>B) Restoring from the exsiting backup files in the PVC
the backup_dir param is for this scenario


Requirements
------------

This role assumes you are authenticated with an Openshift or Kubernetes cluster:
  - The awx-operator has been deployed to the cluster
  - AWX is deployed to via the operator
  - An AWX backup is available on a PVC in your cluster (see the backup [README.md](../backup/README.md))
This role assumes you have storage assigned to AWX by your Administrator.  You'll need a PV and PVC for backup and restore
Place your backup directory (tower-openshift-backup-<date>-<time>) on the root of the PV

*Before Restoring from a backup*, be sure to:
  - delete the old existing AWX CR
  - delete the persistent volume claim (PVC) for the database from the old deployment, which has a name like `postgres-<postgres version>-<deployment-name>-postgres-<postgres version>-0`
  - delete any PGSQL data that resides in the PV,PVC
   <br> `cd` to data path on PV and `rm -rf *`

**Note**: Do not delete the namespace/project, as that will delete the backup and the backup's PVC as well.


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
  deployment_name: <your deployment name>
  backup_name: awxbackup-<YYY-MM-DD>  ## required for scenario A only
  backup_dir: /backups/<folder> ## required for scenario B only
  ## `/backups` is mandatory since your PV will be mounted as `/backups`
  ## <folder> ## is the name of the folder created by the backup earlier
  backup_pvc: <your pvc name>
  postgres_image: <image URL>  ## if using a private repo
  postgres_image_version: <'version'>  ## if using a private repo  ## single quote around version is required
   
```

Note that the `deployment_name` above is the name of the AWX deployment you intend to create and restore to.

The namespace specified is the namespace the resulting AWX deployment will be in.  The namespace you specified must be pre-created.

```
kubectl create ns my-namespace
```

Finally, use `kubectl` to create the restore object in your cluster:

```bash
$ kubectl apply -f restore-awx.yml
```

This will create a new deployment and restore your backup to it.

> :warning: admin_password_secret value will replace the password for the `admin_user` user (by default, this is the `admin` user).

Watch your ansible logs as the restore proceeds
<br>`# kubectl logs -f -n <namespace> deploy/awx-operator-controller-manager`

Check your storage that you have assigned to the restore, it should show that your PV and PVC are bound
<br>`# kubectl get pv`
<br>`NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS    REASON   AGE`
<br>`awx-backup    2Gi        RWX            Delete           Bound    awx/awx-backup                      local-storage            6s`
<br>`postgres-pv   2Gi        RWX            Delete           Bound    awx/postgres-13-awx-postgres-13-0   local-storage            84d`


`# kubectl get pvc -n awx`
<br>`NAME                            STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS    AGE`
<br>`awx-backup                      Bound    awx-backup    2Gi        RWX            local-storage   12s`
<br>`postgres-13-awx-postgres-13-0   Bound    postgres-pv   2Gi        RWX            local-storage   84d`

To check your pod running the job you can run kubectl describe
<br>`# kubectl describe po/restore-awx-db-management -n <namespace_here>`

The path to your PV and PVC need to be present on the node where the pod is running.  Examine the pod events section to see where the pod is running.
<br>
<br>...
<br>`Events:`
 <br> `Type    Reason     Age   From               Message`
  <br>`----    ------     ----  ----               -------`
  <br>`Normal  Scheduled  11s   default-scheduler  Successfully assigned awx/restore-awx-db-management to <hostname>`

Role Variables
--------------

The name of the backup directory can be found as a status on your AWXBackup object.  This can be found in your cluster's console, or with the client as shown below.

```bash
$ kubectl get awxbackup awxbackup1 -o jsonpath="{.items[0].status.backupDirectory}"
/backups/tower-openshift-backup-2021-04-02-03:25:08
```

```
backup_dir: '/backups/tower-openshift-backup-2021-04-02-03:25:08'
```


The name of the PVC can also be found by looking at the backup object.

```bash
$ kubectl get awxbackup awxbackup1 -o jsonpath="{.items[0].status.backupClaim}"
awx-backup-volume-claim
```

```
backup_pvc: 'awx-backup-volume-claim'
```

The backup pvc will be created in the same namespace the awxbackup object is created in.

If a custom postgres configuration secret was used when deploying AWX, it must be set:

```
postgres_configuration_secret: 'awx-postgres-configuration'
```

If the awxbackup object no longer exists, it is still possible to restore from the backup it created by specifying the pvc name and the back directory.

```
backup_pvc: myoldtower-backup-claim
backup_dir: /backups/tower-openshift-backup-2021-04-02-03:25:08
```

Variable to define Pull policy.You can pass other options like `Always`, `always`, `Never`, `never`, `IfNotPresent`, `ifnotpresent`.

```
image_pull_policy: 'IfNotPresent'
```

Variable to define resources limits and request for restore CR.

```
restore_resource_requirements:
  limits:
    cpu: "1000m"
    memory: "4096Mi"
  requests:
    cpu: "25m"
    memory: "32Mi"
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
