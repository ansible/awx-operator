#### CSRF Cookie Secure Setting

With `csrf_cookie_secure`, you can pass the value for `CSRF_COOKIE_SECURE` to `/etc/tower/settings.py`

| Name               | Description        | Default |
| ------------------ | ------------------ | ------- |
| csrf_cookie_secure | CSRF Cookie Secure | ''      |

Example configuration of the `csrf_cookie_secure` setting:

```yaml
  spec:
    csrf_cookie_secure: 'False'
```
