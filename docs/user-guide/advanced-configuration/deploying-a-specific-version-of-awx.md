# Using images from private registries

## Available variables to use images from private registries

There are variables that are customizable for awx the image management.

| Name                          | Description                   | Default                                    |
| ----------------------------- | ----------------------------- | ------------------------------------------ |
| image                         | Path of the image to pull     | quay.io/ansible/awx                        |
| image_version                 | Image version to pull         | value of DEFAULT_AWX_VERSION or latest     |
| image_pull_policy             | The pull policy to adopt      | IfNotPresent                               |
| image_pull_secrets            | The pull secrets to use       | None                                       |
| ee_images                     | A list of EEs to register     | quay.io/ansible/awx-ee:DEFAULT_AWX_VERSION |
| ee_pull_credentials_secret    | The pull secret for ee_images | None                                       |
| redis_image                   | Path of the image to pull     | docker.io/redis                            |
| redis_image_version           | Image version to pull         | latest                                     |
| control_plane_ee_image        | Image version to pull         | quay.io/ansible/awx-ee:DEFAULT_AWX_VERSION |
| init_container_image          | Path of the image to pull     | quay.io/ansible/awx-ee                     |
| init_container_image_version  | Image version to pull         | value of DEFAULT_AWX_VERSION or latest     |
| init_projects_container_image | Image version to pull         | quay.io/centos/centos:stream9              |

Example of customization could be:

```yaml
---
spec:
  ...
  image: myorg/my-custom-awx
  image_version: latest
  image_pull_policy: Always
  image_pull_secrets:
    - pull_secret_name
  ee_images:
    - name: my-custom-awx-ee
      image: myorg/my-custom-awx-ee
  control_plane_ee_image: myorg/my-custom-awx-ee:latest
  init_container_image: myorg/my-custom-awx-ee
  init_container_image_version: latest
  init_projects_container_image: myorg/my-mirrored-centos:stream9
```

!!! warning
    The `image` and `image_version` are intended for local mirroring scenarios. Please note that using a version of AWX other than the one bundled with the `awx-operator` is **not** supported. For the default values, check the [main.yml](https://github.com/ansible/awx-operator/blob/devel/roles/installer/defaults/main.yml) file.

## Default execution environments from private registries

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

## Control plane ee from private registry

The images listed in `ee_images` will be added as globally available Execution Environments. The `control_plane_ee_image` will be used to run project updates. In order to use a private image for any of these you'll need to use `image_pull_secrets` to provide a list of k8s pull secrets to access it. Currently the same secret is used for any of these images supplied at install time.

You can create `image_pull_secret`

```sh
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
