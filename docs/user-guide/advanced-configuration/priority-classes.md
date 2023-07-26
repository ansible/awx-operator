#### Priority Classes

The AWX and Postgres pods can be assigned a custom PriorityClass to rank their importance compared to other pods in your cluster, which determines which pods get evicted first if resources are running low.
First, [create your PriorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass) if needed.
Then set the name of your priority class to the control plane and postgres pods as shown below.

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  ...
  control_plane_priority_class: awx-demo-high-priority
  postgres_priority_class: awx-demo-medium-priority
```
