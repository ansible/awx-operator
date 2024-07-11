#### Use custom image pull secrets

In order to pull images from registries with custom secrets you can use `image_pull_secrets` to provide a list of k8s pull secrets.

To create a pull secrets
```
kubectl create secret docker-registry regcred --docker-server=<your-registry-server> --docker-username=<your-username> --docker-password=<your-password>
```

Then the `image_pull_secrets` can be provided when installing, backing up, or restoring AWX.

Example spec file for installing:

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: myawx
spec:
  image_pull_secrets:
    - regcred
```

Example spec file for backing up:

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWXBackup
metadata:
  name: myawxbackup
  namespace: mynamespace
spec:
  deployment_name: myawx
  image_pull_secrets:
    - regcred
```

Example spec file for restoring:

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWXRestore
metadata:
  name: restore1
  namespace: mynamespace
spec:
  deployment_name: myawx
  backup_name: myawxbackup
  image_pull_secrets:
    - regcred
```
