#### Trusting a Custom Certificate Authority

In cases which you need to trust a custom Certificate Authority, there are few variables you can customize for the `awx-operator`.

Trusting a custom Certificate Authority allows the AWX to access network services configured with SSL certificates issued locally, such as cloning a project from from an internal Git server via HTTPS. It is common for these scenarios, experiencing the error [unable to verify the first certificate](https://github.com/ansible/awx-operator/issues/376).


| Name                             | Description                              | Default |
| -------------------------------- | ---------------------------------------- | --------|
| ldap_cacert_secret               | LDAP Certificate Authority secret name   |  ''     |
| ldap_password_secret             | LDAP BIND DN Password secret name        |  ''     |
| bundle_cacert_secret             | Certificate Authority secret name        |  ''     |
Please note the `awx-operator` will look for the data field `ldap-ca.crt` in the specified secret when using the `ldap_cacert_secret`, whereas the data field `bundle-ca.crt` is required for `bundle_cacert_secret` parameter.

Example of customization could be:

```yaml
---
spec:
  ...
  ldap_cacert_secret: <resourcename>-custom-certs
  ldap_password_secret: <resourcename>-ldap-password
  bundle_cacert_secret: <resourcename>-custom-certs
```

Create the secret with `kustomization.yaml` file:

```yaml
....

secretGenerator:
  - name: <resourcename>-custom-certs
    files:
      - bundle-ca.crt=<path+filename>
    options:
      disableNameSuffixHash: true
      
...
```

Create the secret with CLI:

* Certificate Authority secret

```
# kubectl create secret generic <resourcename>-custom-certs \
    --from-file=ldap-ca.crt=<PATH/TO/YOUR/CA/PEM/FILE>  \
    --from-file=bundle-ca.crt=<PATH/TO/YOUR/CA/PEM/FILE>
```

* LDAP BIND DN Password secret

```
# kubectl create secret generic <resourcename>-ldap-password \
    --from-literal=ldap-password=<your_ldap_dn_password>
```
