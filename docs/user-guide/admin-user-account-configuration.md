### Admin user account configuration

There are three variables that are customizable for the admin user account creation.

| Name                  | Description                                  | Default          |
| --------------------- | -------------------------------------------- | ---------------- |
| admin_user            | Name of the admin user                       | admin            |
| admin_email           | Email of the admin user                      | test@example.com |
| admin_password_secret | Secret that contains the admin user password | Empty string     |


> :warning: **admin_password_secret must be a Kubernetes secret and not your text clear password**.

If `admin_password_secret` is not provided, the operator will look for a secret named `<resourcename>-admin-password` for the admin password. If it is not present, the operator will generate a password and create a Secret from it named `<resourcename>-admin-password`.

To retrieve the admin password, run `kubectl get secret <resourcename>-admin-password -o jsonpath="{.data.password}" | base64 --decode ; echo`

The secret that is expected to be passed should be formatted as follow:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: <resourcename>-admin-password
  namespace: <target namespace>
stringData:
  password: mysuperlongpassword
```

### Secret Key Configuration

This key is used to encrypt sensitive data in the database.

| Name              | Description                                           | Default          |
| ----------------- | ----------------------------------------------------- | ---------------- |
| secret_key_secret | Secret that contains the symmetric key for encryption | Generated     |


> :warning: **secret_key_secret must be a Kubernetes secret and not your text clear secret value**.

If `secret_key_secret` is not provided, the operator will look for a secret named `<resourcename>-secret-key` for the secret key. If it is not present, the operator will generate a password and create a Secret from it named `<resourcename>-secret-key`. It is important to not delete this secret as it will be needed for upgrades and if the pods get scaled down at any point. If you are using a GitOps flow, you will want to pass a secret key secret.

The secret should be formatted as follow:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: custom-awx-secret-key
  namespace: <target namespace>
stringData:
  secret_key: supersecuresecretkey
```

Then specify the secret name on the AWX spec:

```yaml
---
spec:
  ...
  secret_key_secret: custom-awx-secret-key
```
