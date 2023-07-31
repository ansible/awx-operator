#### Session Cookie Secure Setting

With `session_cookie_secure`, you can pass the value for `SESSION_COOKIE_SECURE` to `/etc/tower/settings.py`

| Name                  | Description           | Default |
| --------------------- | --------------------- | ------- |
| session_cookie_secure | Session Cookie Secure | ''      |

Example configuration of the `session_cookie_secure` setting:

```yaml
  spec:
    session_cookie_secure: 'False'
```
