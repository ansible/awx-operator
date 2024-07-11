# Custom Volume and Volume Mount Options

In a scenario where custom volumes and volume mounts are required to either overwrite defaults or mount configuration files.

| Name                               | Description                                              | Default |
| ---------------------------------- | -------------------------------------------------------- | ------- |
| extra_volumes                      | Specify extra volumes to add to the application pod      | ''      |
| web_extra_volume_mounts            | Specify volume mounts to be added to Web container       | ''      |
| task_extra_volume_mounts           | Specify volume mounts to be added to Task container      | ''      |
| rsyslog_extra_volume_mounts        | Specify volume mounts to be added to Rsyslog container   | ''      |
| ee_extra_volume_mounts             | Specify volume mounts to be added to Execution container | ''      |
| init_container_extra_volume_mounts | Specify volume mounts to be added to Init container      | ''      |
| init_container_extra_commands      | Specify additional commands for Init container           | ''      |

!!! warning
    The `ee_extra_volume_mounts` and `extra_volumes` will only take effect to the globally available Execution Environments. For custom `ee`, please [customize the Pod spec](https://docs.ansible.com/ansible-tower/latest/html/administration/external_execution_envs.html#customize-the-pod-spec).

Example configuration for ConfigMap

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: <resourcename>-extra-config
  namespace: <target namespace>
data:
  ansible.cfg: |
    [defaults]
    remote_tmp = /tmp
    [ssh_connection]
    ssh_args = -C -o ControlMaster=auto -o ControlPersist=60s
```

Example spec file for volumes and volume mounts

```yaml
---
spec:
  ...
  extra_volumes: |
    - name: ansible-cfg
      configMap:
        defaultMode: 420
        items:
          - key: ansible.cfg
            path: ansible.cfg
        name: <resourcename>-extra-config
    - name: shared-volume
      persistentVolumeClaim:
        claimName: my-external-volume-claim

  init_container_extra_volume_mounts: |
    - name: shared-volume
      mountPath: /shared

  init_container_extra_commands: |
    # set proper permissions (rwx) for the awx user
    chmod 775 /shared
    chgrp 1000 /shared

  ee_extra_volume_mounts: |
    - name: ansible-cfg
      mountPath: /etc/ansible/ansible.cfg
      subPath: ansible.cfg
```

!!! warning
    **Volume and VolumeMount names cannot contain underscores(_)**

## Custom UWSGI Configuration

We allow the customization of two UWSGI parameters:

* [processes](https://uwsgi-docs.readthedocs.io/en/latest/Options.html#processes) with `uwsgi_processes` (default 5)
* [listen](https://uwsgi-docs.readthedocs.io/en/latest/Options.html#listen) with `uwsgi_listen_queue_size` (default 128)

**Note:** Increasing the listen queue beyond 128 requires that the sysctl setting net.core.somaxconn be set to an equal value or higher.
  The operator will set the appropriate securityContext sysctl value for you, but it is a required that this sysctl be added to an allowlist on the kubelet level. [See kubernetes docs about allowing this sysctl setting](https://kubernetes.io/docs/tasks/administer-cluster/sysctl-cluster/#enabling-unsafe-sysctls).

These vars relate to the vertical and horizontal scalibility of the web service.

Increasing the number of processes allows more requests to be actively handled
per web pod, but will consume more CPU and Memory and the resource requests
should be increased in tandem.  Increasing the listen queue allows uwsgi to
queue up requests not yet being handled by the active worker processes, which
may allow the web pods to handle more "bursty" request patterns if many
requests (more than 128) tend to come in a short period of time, but can all be
handled before any other time outs may apply. Also see related nginx
configuration.

## Custom Nginx Configuration

Using the [extra_volumes feature](#custom-volume-and-volume-mount-options), it is possible to extend the nginx.conf.

1. Create a ConfigMap with the extra settings you want to include in the nginx.conf
2. Create an extra_volumes entry in the AWX spec for this ConfigMap
3. Create an web_extra_volume_mounts entry in the AWX spec to mount this volume

The AWX nginx config automatically includes /etc/nginx/conf.d/*.conf if present.

Additionally there are some global configuration values in the base nginx
config that are available for setting with individual variables.
These vars relate to the vertical and horizontal scalibility of the web service.
Increasing the number of processes allows more requests to be actively handled
per web pod, but will consume more CPU and Memory and the resource requests
should be increased in tandem.  Increasing the listen queue allows nginx to
queue up requests not yet being handled by the active worker processes, which
may allow the web pods to handle more "bursty" request patterns if many
requests (more than 128) tend to come in a short period of time, but can all be
handled before any other time outs may apply. Also see related uwsgi
configuration.

* [worker_processes](http://nginx.org/en/docs/ngx_core_module.html#worker_processes) with `nginx_worker_processes` (default of 1)
* [worker_cpu_affinity](http://nginx.org/en/docs/ngx_core_module.html#worker_cpu_affinity) with `nginx_worker_cpu_affinity` (default "auto")
* [worker_connections](http://nginx.org/en/docs/ngx_core_module.html#worker_connections) with `nginx_worker_connections` (minimum of 1024)
* [listen](https://nginx.org/en/docs/http/ngx_http_core_module.html#listen) with `nginx_listen_queue_size` (default same as uwsgi listen queue size)

## Custom Logos

You can use custom volume mounts to mount in your own logos to be displayed instead of the AWX logo.
There are two different logos, one to be displayed on page headers, and one for the login screen.

First, create configmaps for the logos from local `logo-login.svg` and `logo-header.svg` files.

```bash
kubectl create configmap logo-login-configmap --from-file logo-login.svg
kubectl create configmap logo-header-configmap --from-file logo-header.svg
```

Then specify the extra_volume and web_extra_volume_mounts on your AWX CR spec

```yaml
---
spec:
  ...
  extra_volumes: |
    - name: logo-login
      configMap:
        defaultMode: 420
        items:
          - key: logo-login.svg
            path: logo-login.svg
        name: logo-login-configmap
    - name: logo-header
      configMap:
        defaultMode: 420
        items:
          - key: logo-header.svg
            path: logo-header.svg
        name: logo-header-configmap
  web_extra_volume_mounts: |
    - name: logo-login
      mountPath: /var/lib/awx/public/static/media/logo-login.svg
      subPath: logo-login.svg
    - name: logo-header
      mountPath: /var/lib/awx/public/static/media/logo-header.svg
      subPath: logo-header.svg
```

## Custom Favicon

You can also use custom volume mounts to mount in your own favicon to be displayed in your AWX browser tab.

First, create the configmap from a local `favicon.ico` file.

```bash
kubectl create configmap favicon-configmap --from-file favicon.ico
```

Then specify the extra_volume and web_extra_volume_mounts on your AWX CR spec

```yaml
---
spec:
  ...
  extra_volumes: |
    - name: favicon
      configMap:
        defaultMode: 420
        items:
          - key: favicon.ico
            path: favicon.ico
        name: favicon-configmap
  web_extra_volume_mounts: |
    - name: favicon
      mountPath: /var/lib/awx/public/static/media/favicon.ico
      subPath: favicon.ico
```

## Custom AWX Configuration

Refer to the [Extra Settings](./extra-settings.md) documentation for customizing the AWX configuration.
