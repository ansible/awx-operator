#### Default execution environments from private registries

In order to register default execution environments from private registries, the Custom Resource needs to know about the pull credentials. Those credentials should be stored as a secret and either specified as `ee_pull_credentials_secret` at the CR spec level, or simply be present on the namespace under the name `<resourcename>-ee-pull-credentials` . Instance initialization will register a `Container registry` type credential on the deployed instance and assign it to the registered default execution environments.

The secret should be formatted as follows:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: <resourcename>-ee-pull-credentials
  namespace: <target namespace>
stringData:
  url: <registry url. i.e. quay.io>
  username: <username to connect as>
  password: <password to connect with>
  ssl_verify: <Optional attribute. Whether verify ssl connection or not. Accepted values "True" (default), "False" >
type: Opaque
```

##### Control plane ee from private registry
The images listed in "ee_images" will be added as globally available Execution Environments. The "control_plane_ee_image" will be used to run project updates. In order to use a private image for any of these you'll need to use `image_pull_secrets` to provide a list of k8s pull secrets to access it. Currently the same secret is used for any of these images supplied at install time.

You can create `image_pull_secret`
```
kubectl create secret <resoucename>-cp-pull-credentials regcred --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
```
If you need more control (for example, to set a namespace or a label on the new secret) then you can customize the Secret before storing it

Example spec file extra-config

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: <resoucename>-cp-pull-credentials
  namespace: <target namespace>
data:
  .dockerconfigjson: <base64 docker config>
type: kubernetes.io/dockerconfigjson
```
