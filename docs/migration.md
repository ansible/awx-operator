# Migrating data from an old AWX instance

To migrate data from an older AWX installation, you must provide some information via Secrets.

## Creating Secrets for Migration

### Secret Key

You can find your old secret key in the inventory file you used to deploy AWX in releases prior to version 18. 

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: <resourcename>-secret-key
  namespace: <target namespace>
stringData:
  secret_key: <old-secret-key>
type: Opaque
```

**Note**: `<resourcename>` must match the `name` of the AWX object you are creating. In our example below, it is `awx`.

### Old Databse Credentials

The secret should be formatted as follows:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: <resourcename>-old-postgres-configuration
  namespace: <target namespace>
stringData:
  host: <external ip or url resolvable by the cluster>
  port: <external port, this usually defaults to 5432>
  database: <desired database name>
  username: <username to connect as>
  password: <password to connect with>
type: Opaque
```

> For `host`, a URL resolvable by the cluster could look something like `postgresql.<namespace>.svc.cluster.local`, where `<namespace>` is filled in with the namespace of the AWX deployment you are migrating data from.

## Deploy AWX

When you apply your AWX object, you must specify the name to the database secret you created above:

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
spec:
  tower_old_postgres_configuration_secret: <resourcename>-old-postgres-configuration
  ...
```
