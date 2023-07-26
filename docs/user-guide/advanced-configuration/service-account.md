#### Service Account

If you need to modify some `ServiceAccount` proprieties

| Name                        | Description                       | Default |
| --------------------------- | --------------------------------- | ------- |
| service_account_annotations | Annotations to the ServiceAccount | ''      |

Example configuration of environment variables

```yaml
  spec:
    service_account_annotations: |
      eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME>
```
