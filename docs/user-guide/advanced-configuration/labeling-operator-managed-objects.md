#### Labeling operator managed objects

In certain situations labeling of Kubernetes objects managed by the operator
might be desired (e.g. for owner identification purposes). For that
`additional_labels` parameter could be used

| Name                        | Description                                                                              | Default |
| --------------------------- | ---------------------------------------------------------------------------------------- | ------- |
| additional_labels           | Additional labels defined on the resource, which should be propagated to child resources | []      |

Example configuration where only `my/team` and `my/service` labels will be
propagated to child objects (`Deployment`, `Secret`s, `ServiceAccount`, etc):

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
  labels:
    my/team: "foo"
    my/service: "bar"
    my/do-not-inherit: "yes"
spec:
  additional_labels:
  - my/team
  - my/service
...
```
