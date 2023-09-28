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
  namespace: <target-namespace>
stringData:
  secret_key: <old-secret-key>
type: Opaque
```

**Note**: `<resourcename>` must match the `name` of the AWX object you are creating. In our example below, it is `awx`.

### Old Database Credentials

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
  port: "<external port, this usually defaults to 5432>"    # quotes are required
  database: <desired database name>
  username: <username to connect as>
  password: <password to connect with>
type: Opaque
```

> For `host`, a URL resolvable by the cluster could look something like `postgresql.<namespace>.svc.<cluster domain>`, where `<namespace>` is filled in with the namespace of the AWX deployment you are migrating data from, and `<cluster domain>` is filled in with the internal kubernretes cluster domain (In most cases it's `cluster.local`).

If your AWX deployment is already using an external database server or its database is otherwise not managed
by the AWX deployment, you can instead create the same secret as above but omit the `-old-` from the `name`.
In the next section pass it in through `postgres_configuration_secret` instead, omitting the `_old_`
from the key and ensuring the value matches the name of the secret. This will make AWX pick up on the existing
database and apply any pending migrations. It is strongly recommended to backup your database beforehand.

The postgresql pod for the old deployment is used when streaming data to the new postgresql pod.  If your postgresql pod has a custom label,
you can pass that via the `postgres_label_selector` variable to make sure the postgresql pod can be found.

## Deploy AWX

When you apply your AWX object, you must specify the name to the database secret you created above:

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
spec:
  old_postgres_configuration_secret: <resourcename>-old-postgres-configuration
  secret_key_secret: <resourcename>-secret-key
  ...
```
## Important Note
If you intend to put all the above in one file, make sure to separate each block with three dashes like so:

```yaml
---
# Secret key

---
# Database creds

---
# AWX Config
```
Failing to do so will lead to an inoperable setup.
