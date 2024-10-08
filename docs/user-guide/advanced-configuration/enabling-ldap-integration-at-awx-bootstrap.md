# Enabling LDAP Integration at AWX bootstrap (Deprecated)

A sample of extra settings can be found as below. All possible options can be found here: <https://django-auth-ldap.readthedocs.io/en/latest/reference.html#settings>

Refer to the [Extra Settings](./extra-settings.md) page for more information on how to configure extra settings.

!!! tip
    To trust a custom Certificate Authority for your LDAP server, or to specify password LDAP bind DN, refer to the [Trusting a Custom Certificate Authority](./trusting-a-custom-certificate-authority.md) page.

## Configure LDAP integration via `extra_settings_files`

Create a Python file with arbitrary name, e.g. `custom_ldap_settings.py`, and add the following content for example:

```python title="custom_ldap_settings.py"
AUTH_LDAP_SERVER_URI = "ldaps://ad01.abc.com:636 ldaps://ad02.abc.com:636"
AUTH_LDAP_BIND_DN = "CN=LDAP User,OU=Service Accounts,DC=abc,DC=com"
AUTH_LDAP_USER_SEARCH = LDAPSearch(
    "DC=abc,DC=com",
    ldap.SCOPE_SUBTREE,
    "(sAMAccountName=%(user)s)",
)
AUTH_LDAP_GROUP_SEARCH = LDAPSearch(
    "OU=Groups,DC=abc,DC=com",
    ldap.SCOPE_SUBTREE,
    "(objectClass=group)",
)
AUTH_LDAP_GROUP_TYPE = GroupOfNamesType()
AUTH_LDAP_USER_ATTR_MAP = {
    "first_name": "givenName",
    "last_name": "sn",
    "email": "mail",
}
AUTH_LDAP_REQUIRE_GROUP = "CN=operators,OU=Groups,DC=abc,DC=com"
AUTH_LDAP_USER_FLAGS_BY_GROUP = {
    "is_superuser": ["CN=admin,OU=Groups,DC=abc,DC=com"],
}
AUTH_LDAP_ORGANIZATION_MAP = {
    "abc": {
        "admins": "CN=admin,OU=Groups,DC=abc,DC=com",
        "remove_admins": False,
        "remove_users": False,
        "users": True,
    }
}
AUTH_LDAP_TEAM_MAP = {
    "admin": {
        "organization": "abc",
        "remove": True,
        "users": "CN=admin,OU=Groups,DC=abc,DC=com",
    }
}
```

Create a ConfigMap with the content of the above Python file.

```bash
kubectl create configmap custom-ldap-settings \
  --from-file /PATH/TO/YOUR/custom_ldap_settings.py
```

Then specify this ConfigMap to the `extra_settings_files` parameter.

```yaml
spec:
  extra_settings_files:
    configmaps:
      - name: custom-ldap-settings
        key: custom_ldap_settings.py
```

!!! note
    If you have embedded some sensitive information like passwords in the Python file, you can create and pass a Secret instead of a ConfigMap.

    ```bash
    kubectl create secret generic custom-ldap-settings \
      --from-file /PATH/TO/YOUR/custom_ldap_settings.py
    ```

    ```yaml
    spec:
      extra_settings_files:
        secrets:
          - name: custom-ldap-settings
            key: custom_ldap_settings.py
    ```

## Configure LDAP integration via `extra_settings`

!!! note
    These values are inserted into a Python file, so pay close attention to which values need quotes and which do not.

```yaml
spec:
  extra_settings:
    - setting: AUTH_LDAP_SERVER_URI
      value: >-
        "ldaps://ad01.abc.com:636 ldaps://ad02.abc.com:636"

    - setting: AUTH_LDAP_BIND_DN
      value: >-
        "CN=LDAP User,OU=Service Accounts,DC=abc,DC=com"

    - setting: AUTH_LDAP_USER_SEARCH
      value: 'LDAPSearch("DC=abc,DC=com",ldap.SCOPE_SUBTREE,"(sAMAccountName=%(user)s)",)'

    - setting: AUTH_LDAP_GROUP_SEARCH
      value: 'LDAPSearch("OU=Groups,DC=abc,DC=com",ldap.SCOPE_SUBTREE,"(objectClass=group)",)'

    - setting: AUTH_LDAP_GROUP_TYPE
      value: 'GroupOfNamesType()'

    - setting: AUTH_LDAP_USER_ATTR_MAP
      value: '{"first_name": "givenName","last_name": "sn","email": "mail"}'

    - setting: AUTH_LDAP_REQUIRE_GROUP
      value: >-
        "CN=operators,OU=Groups,DC=abc,DC=com"
    - setting: AUTH_LDAP_USER_FLAGS_BY_GROUP
      value: {
        "is_superuser": [
          "CN=admin,OU=Groups,DC=abc,DC=com"
        ]
      }

    - setting: AUTH_LDAP_ORGANIZATION_MAP
      value: {
        "abc": {
          "admins": "CN=admin,OU=Groups,DC=abc,DC=com",
          "remove_users": false,
          "remove_admins": false,
          "users": true
        }
      }

    - setting: AUTH_LDAP_TEAM_MAP
      value: {
        "admin": {
          "remove": true,
          "users": "CN=admin,OU=Groups,DC=abc,DC=com",
          "organization": "abc"
        }
      }
```
