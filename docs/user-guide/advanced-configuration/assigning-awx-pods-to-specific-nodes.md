#### Assigning AWX pods to specific nodes

You can constrain the AWX pods created by the operator to run on a certain subset of nodes. `node_selector` and `postgres_selector` constrains
the AWX pods to run only on the nodes that match all the specified key/value pairs. `tolerations` and `postgres_tolerations` allow the AWX
pods to be scheduled onto nodes with matching taints.
The ability to specify topologySpreadConstraints is also allowed through `topology_spread_constraints`
If you want to use affinity rules for your AWX pod you can use the `affinity` option.

If you want to constrain the web and task pods individually, you can do so by specificying the deployment type before the specific setting. For
example, specifying `task_tolerations` will allow the AWX task pod to be scheduled onto nodes with matching taints. 

| Name                             | Description                              | Default                          |
| -------------------------------- | ---------------------------------------- | -------------------------------- |
| postgres_image                   | Path of the image to pull                | quay.io/sclorg/postgresql-15-c9s |
| postgres_image_version           | Image version to pull                    | latest                           |
| node_selector                    | AWX pods' nodeSelector                   | ''                               |
| web_node_selector                | AWX web pods' nodeSelector               | ''                               |
| task_node_selector               | AWX task pods' nodeSelector              | ''                               |
| topology_spread_constraints      | AWX pods' topologySpreadConstraints      | ''                               |
| web_topology_spread_constraints  | AWX web pods' topologySpreadConstraints  | ''                               |
| task_topology_spread_constraints | AWX task pods' topologySpreadConstraints | ''                               |
| affinity                         | AWX pods' affinity rules                 | ''                               |
| web_affinity                     | AWX web pods' affinity rules             | ''                               |
| task_affinity                    | AWX task pods' affinity rules            | ''                               |
| tolerations                      | AWX pods' tolerations                    | ''                               |
| web_tolerations                  | AWX web pods' tolerations                | ''                               |
| task_tolerations                 | AWX task pods' tolerations               | ''                               |
| annotations                      | AWX pods' annotations                    | ''                               |
| postgres_selector                | Postgres pods' nodeSelector              | ''                               |
| postgres_tolerations             | Postgres pods' tolerations               | ''                               |

Example of customization could be:

```yaml
---
spec:
  ...
  node_selector: |
    disktype: ssd
    kubernetes.io/arch: amd64
    kubernetes.io/os: linux
  topology_spread_constraints: |
    - maxSkew: 100
      topologyKey: "topology.kubernetes.io/zone"
      whenUnsatisfiable: "ScheduleAnyway"
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: "<resourcename>"
  tolerations: |
    - key: "dedicated"
      operator: "Equal"
      value: "AWX"
      effect: "NoSchedule"
  task_tolerations: |
    - key: "dedicated"
      operator: "Equal"
      value: "AWX_task"
      effect: "NoSchedule"
  postgres_selector: |
    disktype: ssd
    kubernetes.io/arch: amd64
    kubernetes.io/os: linux
  postgres_tolerations: |
    - key: "dedicated"
      operator: "Equal"
      value: "AWX"
      effect: "NoSchedule"
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: another-node-label-key
            operator: In
            values:
            - another-node-label-value
            - another-node-label-value
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: security
              operator: In
              values:
              - S2
          topologyKey: topology.kubernetes.io/zone
```

#### Special Note on DB-Migration Job Scheduling

For the **db-migration job**, which applies database migrations at cluster startup, you can specify scheduling settings using the `task_*` configurations such as `task_node_selector`, `task_tolerations`, etc.  
If these task-specific settings are not defined, the job will automatically use the global AWX configurations like `node_selector` and `tolerations`.
