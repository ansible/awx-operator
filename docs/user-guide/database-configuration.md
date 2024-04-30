### Database Configuration

#### PostgreSQL Version

The default PostgreSQL version for the version of AWX bundled with the latest version of the awx-operator is PostgreSQL 15. You can find this default for a given version by at the default value for [supported_pg_version](https://github.com/ansible/awx-operator/blob/ffba1b4712a0b03f1faedfa70e3a9ef0d443e4a6/roles/installer/vars/main.yml#L7).

We only have coverage for the default version of PostgreSQL. Newer versions of PostgreSQL will likely work, but should only be configured as an external database. If your database is managed by the awx-operator (default if you don't specify a `postgres_configuration_secret`), then you should not override the default version as this may cause issues when awx-operator tries to upgrade your postgresql pod.

#### External PostgreSQL Service

To configure AWX to use an external database, the Custom Resource needs to know about the connection details. To do this, create a k8s secret with those connection details and specify the name of the secret as `postgres_configuration_secret` at the CR spec level.


The secret should be formatted as follows:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: <resourcename>-postgres-configuration
  namespace: <target namespace>
stringData:
  host: <external ip or url resolvable by the cluster>
  port: <external port, this usually defaults to 5432>
  database: <desired database name>
  username: <username to connect as>
  password: <password to connect with>
  sslmode: prefer
  target_session_attrs: read-write
  type: unmanaged
type: Opaque
```

> Please ensure that the value for the variable `password` should _not_ contain single or double quotes (`'`, `"`) or backslashes (`\`) to avoid any issues during deployment, [backup](https://github.com/ansible/awx-operator/tree/devel/roles/backup) or [restoration](https://github.com/ansible/awx-operator/tree/devel/roles/restore).

> It is possible to set a specific username, password, port, or database, but still have the database managed by the operator. In this case, when creating the postgres-configuration secret, the `type: managed` field should be added.

**Note**: The variable `sslmode` is valid for `external` databases only. The allowed values are: `prefer`, `disable`, `allow`, `require`, `verify-ca`, `verify-full`.

**Note**: The variable `target_session_attrs` is only useful for `clustered external` databases. The allowed values are: `any` (default), `read-write`, `read-only`, `primary`, `standby` and `prefer-standby`, whereby only `read-write` and `primary` really make sense in AWX use, as you want to connect to a database node that offers write support.

Once the secret is created, you can specify it on your spec:

```yaml
---
spec:
  ...
  postgres_configuration_secret: <name-of-your-secret>
```

#### Migrating data from an old AWX instance

For instructions on how to migrate from an older version of AWX, see [migration.md](../migration/migration.md).

#### Managed PostgreSQL Service

If you don't have access to an external PostgreSQL service, the AWX operator can deploy one for you along side the AWX instance itself.

The following variables are customizable for the managed PostgreSQL service

| Name                                          | Description                                                     | Default                                 |
| --------------------------------------------- | --------------------------------------------------------------- | --------------------------------------- |
| postgres_image                                | Path of the image to pull                                       | quay.io/sclorg/postgresql-15-c9s        |
| postgres_image_version                        | Image version to pull                                           | latest                                  |
| postgres_resource_requirements                | PostgreSQL container (and initContainer) resource requirements  | requests: {cpu: 10m, memory: 64Mi}      |
| postgres_storage_requirements                 | PostgreSQL container storage requirements                       | requests: {storage: 8Gi}                |
| postgres_storage_class                        | PostgreSQL PV storage class                                     | Empty string                            |
| postgres_priority_class                       | Priority class used for PostgreSQL pod                          | Empty string                            |

Example of customization could be:

```yaml
---
spec:
  ...
  postgres_resource_requirements:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: '1'
      memory: 4Gi
  postgres_storage_requirements:
    requests:
      storage: 8Gi
    limits:
      storage: 50Gi
  postgres_storage_class: fast-ssd
  postgres_extra_args:
    - '-c'
    - 'max_connections=1000'
```

**Note**: If `postgres_storage_class` is not defined, PostgreSQL will store it's data on a volume using the default storage class for your cluster.

#### Note about overriding the postgres image

We recommend you use the default image sclorg image. If you are coming from a deployment using the old postgres image from dockerhub (postgres:13), upgrading from awx-operator version 2.12.2 and below to 2.15.0+ will handle migrating your data to the new postgresql image (postgresql-15-c9s).

You can no longer configure a custom `postgres_data_path` because it is hardcoded in the quay.io/sclorg/postgresql-15-c9s image.

If you override the postgres image to use a custom postgres image like postgres:15 for example, the default data directory path may be different. These images cannot be used interchangeably.

#### Initialize Postgres data volume

When using a hostPath backed PVC and some other storage classes like longhorn storagfe, the postgres data directory needs to be accessible by the user in the postgres pod (UID 26).

To initialize this directory with the correct permissions, configure the following setting, which will use an init container to set the permissions in the postgres volume.

```yaml
spec:
  postgres_data_volume_init: true
```

Should you need to modify the init container commands, there is an example below.

```yaml
postgres_init_container_commands: |
  chown 26:0 /var/lib/pgsql/data
  chmod 700 /var/lib/pgsql/data
```
