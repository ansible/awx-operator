### Upgrading

To upgrade AWX, it is recommended to upgrade the awx-operator to the version that maps to the desired version of AWX. To find the version of AWX that will be installed by the awx-operator by default, check the version specified in the `DEFAULT_AWX_VERSION` variable for that particular release. You can do so by running the following command

```shell
AWX_OPERATOR_VERSION=2.8.0
docker run --entrypoint="" quay.io/ansible/awx-operator:$AWX_OPERATOR_VERSION bash -c "env | grep DEFAULT_AWX_VERSION"
```

Apply the awx-operator.yml for that release to upgrade the operator, and in turn also upgrade your AWX deployment.

#### Backup

The first part of any upgrade should be a backup. Note, there are secrets in the pod which work in conjunction with the database. Having just a database backup without the required secrets will not be sufficient for recovering from an issue when upgrading to a new version. See the [backup role documentation](https://github.com/ansible/awx-operator/tree/devel/roles/backup) for information on how to backup your database and secrets.

In the event you need to recover the backup see the [restore role documentation](https://github.com/ansible/awx-operator/tree/devel/roles/restore). _Before Restoring from a backup_, be sure to:

- delete the old existing AWX CR
- delete the persistent volume claim (PVC) for the database from the old deployment, which has a name like `postgres-15-<deployment-name>-postgres-15-0`

**Note**: Do not delete the namespace/project, as that will delete the backup and the backup's PVC as well.

#### PostgreSQL Upgrade Considerations

If there is a PostgreSQL major version upgrade, after the data directory on the PVC is migrated to the new version, the old PVC is kept by default.
This provides the ability to roll back if needed, but can take up extra storage space in your cluster unnecessarily. You can configure it to be deleted automatically after a successful upgrade by setting the following variable on the AWX spec.

```yaml
spec:
  postgres_keep_pvc_after_upgrade: False
```

#### v0.14.0

##### Cluster-scope to Namespace-scope considerations

Starting with awx-operator 0.14.0, AWX can only be deployed in the namespace that the operator exists in. This is called a namespace-scoped operator. If you are upgrading from an earlier version, you will want to
delete your existing `awx-operator` service account, role and role binding.

##### Project is now based on v1.x of the operator-sdk project

Starting with awx-operator 0.14.0, the project is now based on operator-sdk 1.x. You may need to manually delete your old operator Deployment to avoid issues.

##### Steps to upgrade

Delete your old AWX Operator and existing `awx-operator` service account, role and role binding in `default` namespace first:

```
$ kubectl -n default delete deployment awx-operator
$ kubectl -n default delete serviceaccount awx-operator
$ kubectl -n default delete clusterrolebinding awx-operator
$ kubectl -n default delete clusterrole awx-operator
```

Then install the new AWX Operator by following the instructions in [Basic Install](#basic-install-on-existing-cluster). The `NAMESPACE` environment variable have to be the name of the namespace in which your old AWX instance resides.

Once the new AWX Operator is up and running, your AWX deployment will also be upgraded.
