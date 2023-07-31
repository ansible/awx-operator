#### Enabling LDAP Integration at AWX bootstrap

A sample of extra settings can be found as below. All possible options can be found here: https://django-auth-ldap.readthedocs.io/en/latest/reference.html#settings

> **NOTE:** These values are inserted into a Python file, so pay close attention to which values need quotes and which do not.

```yaml
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
