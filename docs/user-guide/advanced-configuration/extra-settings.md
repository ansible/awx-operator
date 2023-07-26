#### Extra Settings

With`extra_settings`, you can pass multiple custom settings via the `awx-operator`. The parameter `extra_settings`  will be appended to the `/etc/tower/settings.py` and can be an alternative to the `extra_volumes` parameter.

| Name           | Description    | Default |
| -------------- | -------------- | ------- |
| extra_settings | Extra settings | ''      |

**Note:** Parameters configured in `extra_settings` are set as read-only settings in AWX.  As a result, they cannot be changed in the UI after deployment. If you need to change the setting after the initial deployment, you need to change it on the AWX CR spec.  

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
