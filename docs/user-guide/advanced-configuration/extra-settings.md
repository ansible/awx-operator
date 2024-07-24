# Extra Settings

With `extra_settings` and `extra_settings_files`, you can pass multiple custom settings to AWX via the AWX Operator.

!!! note
    Parameters configured in `extra_settings` or `extra_settings_files` are set as read-only settings in AWX. As a result, they cannot be changed in the UI after deployment.

    If you need to change the setting after the initial deployment, you need to change it on the AWX CR spec (for `extra_settings`) or corresponding ConfigMap or Secret (for `extra_settings_files`). After updating ConfigMap or Secret, you need to restart the AWX pods to apply the changes.

!!! note
    If the same setting is set in both `extra_settings` and `extra_settings_files`, the setting in `extra_settings_files` will take precedence.

## Add extra settings with `extra_settings`

You can pass extra settings by specifying the pair of the setting name and value as the `extra_settings` parameter.

The settings passed via `extra_settings` will be appended to the `/etc/tower/settings.py`.

| Name           | Description    | Default   |
| -------------- | -------------- | --------- |
| extra_settings | Extra settings | `[]`      |

Example configuration of `extra_settings` parameter

```yaml
spec:
  extra_settings:
    - setting: MAX_PAGE_SIZE
      value: "500"

    - setting: AUTH_LDAP_BIND_DN
      value: "cn=admin,dc=example,dc=com"

    - setting: LOG_AGGREGATOR_LEVEL
      value: "'DEBUG'"
```

Note for some settings, such as `LOG_AGGREGATOR_LEVEL`, the value may need double quotes.

## Add extra settings with `extra_settings_files`

You can pass extra settings by specifying the additional settings files in the ConfigMaps or Secrets as the `extra_settings_files` parameter.

The settings files passed via `extra_settings_files` will be mounted as the files under the `/etc/tower/conf.d`.

| Name                 | Description          | Default   |
| -------------------- | -------------------- | --------- |
| extra_settings_files | Extra settings files | `{}`      |

!!! note
    If the same setting is set in multiple files in `extra_settings_files`, it would be difficult to predict which would be adopted since these files are loaded in arbitrary order that [`glob`](https://docs.python.org/3/library/glob.html) returns. For a reliable setting, do not include the same key in more than one file.

Create ConfigMaps or Secrets that contain custom settings files (`*.py`).

```python title="custom_job_settings.py"
AWX_TASK_ENV = {
    "HTTPS_PROXY": "http://proxy.example.com:3128",
    "HTTP_PROXY": "http://proxy.example.com:3128",
    "NO_PROXY": "127.0.0.1,localhost,.example.com"
}
GALAXY_TASK_ENV = {
    "ANSIBLE_FORCE_COLOR": "false",
    "GIT_SSH_COMMAND": "ssh -o StrictHostKeyChecking=no",
}
```

```python title="custom_system_settings.py"
REMOTE_HOST_HEADERS = [
    "HTTP_X_FORWARDED_FOR",
    "REMOTE_ADDR",
    "REMOTE_HOST",
]
```

```python title="custom_passwords.py"
SUBSCRIPTIONS_PASSWORD = "my-super-secure-subscription-password123!"
REDHAT_PASSWORD = "my-super-secure-redhat-password123!"
```

```bash title="Create ConfigMap and Secret"
# Create ConfigMap
kubectl create configmap my-custom-settings \
  --from-file /PATH/TO/YOUR/custom_job_settings.py \
  --from-file /PATH/TO/YOUR/custom_system_settings.py

# Create Secret
kubectl create secret generic my-custom-passwords \
  --from-file /PATH/TO/YOUR/custom_passwords.py
```

Then specify them in the AWX CR spec. Here is an example configuration of `extra_settings_files` parameter.

```yaml
spec:
  extra_settings_files:
    configmaps:
      - name: my-custom-settings        # The name of the ConfigMap
        key: custom_job_settings.py     # The key in the ConfigMap, which means the file name
      - name: my-custom-settings
        key: custom_system_settings.py
    secrets:
      - name: my-custom-passwords       # The name of the Secret
        key: custom_passwords.py        # The key in the Secret, which means the file name
```

!!! Warning "Restriction"
    There are some restrictions on the ConfigMaps or Secrets used in `extra_settings_files`.

    - The keys in ConfigMaps or Secrets MUST be the name of python files and MUST end with `.py`
    - The keys in ConfigMaps or Secrets MUST consists of alphanumeric characters, `-`, `_` or `.`
    - The keys in ConfigMaps or Secrets are converted to the following strings, which MUST not exceed 63 characters
        - Keys in ConfigMaps: `<instance name>-<KEY>-configmap`
        - Keys in Secrets: `<instance name>-<KEY>-secret`
    - Following keys are reserved and MUST NOT be used in ConfigMaps or Secrets
        - `credentials.py`
        - `execution_environments.py`
        - `ldap.py`

    Refer to the Kubernetes documentations ([[1]](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/config-map-v1/), [[2]](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/secret-v1/), [[3]](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/volume/), [[4]](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/)) for more information about character types and length restrictions.
