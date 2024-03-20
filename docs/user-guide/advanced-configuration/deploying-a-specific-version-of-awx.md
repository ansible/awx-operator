#### Deploying a specific version of AWX

There are a few variables that are customizable for awx the image management.

| Name                          | Description               | Default                                    |
| ----------------------------- | ------------------------- | ------------------------------------------ |
| image                         | Path of the image to pull | quay.io/ansible/awx                        |
| image_version                 | Image version to pull     | value of DEFAULT_AWX_VERSION or latest     |
| image_pull_policy             | The pull policy to adopt  | IfNotPresent                               |
| image_pull_secrets            | The pull secrets to use   | None                                       |
| ee_images                     | A list of EEs to register | quay.io/ansible/awx-ee:DEFAULT_AWX_VERSION |
| redis_image                   | Path of the image to pull | docker.io/redis                            |
| redis_image_version           | Image version to pull     | latest                                     |
| control_plane_ee_image        | Image version to pull     | quay.io/ansible/awx-ee:DEFAULT_AWX_VERSION |
| init_container_image          | Path of the image to pull | quay.io/ansible/awx-ee                     |
| init_container_image_version  | Image version to pull     | value of DEFAULT_AWX_VERSION or latest     |
| init_projects_container_image | Image version to pull     | quay.io/centos/centos:stream9              |

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

**Note**: The `image` and `image_version` are intended for local mirroring scenarios. Please note that using a version of AWX other than the one bundled with the `awx-operator` is **not** supported. For the default values, check the [main.yml](https://github.com/ansible/awx-operator/blob/devel/roles/installer/defaults/main.yml) file.
