#### Exporting Environment Variables to Containers

If you need to export custom environment variables to your containers.

| Name              | Description                                            | Default |
| ----------------- | ------------------------------------------------------ | ------- |
| task_extra_env    | Environment variables to be added to Task container    | ''      |
| web_extra_env     | Environment variables to be added to Web container     | ''      |
| rsyslog_extra_env | Environment variables to be added to Rsyslog container | ''      |
| ee_extra_env      | Environment variables to be added to EE container      | ''      |

> :warning: The `ee_extra_env` will only take effect to the globally available Execution Environments. For custom `ee`, please [customize the Pod spec](https://docs.ansible.com/ansible-tower/latest/html/administration/external_execution_envs.html#customize-the-pod-spec).

Example configuration of environment variables

```yaml
  spec:
    task_extra_env: |
      - name: MYCUSTOMVAR
        value: foo
    web_extra_env: |
      - name: MYCUSTOMVAR
        value: foo
    rsyslog_extra_env: |
      - name: MYCUSTOMVAR
        value: foo
    ee_extra_env: |
      - name: MYCUSTOMVAR
        value: foo
```
