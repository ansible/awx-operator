### Horizontal Pod Autoscaler (HPA)

Horizontal Pod Autoscaler allows Kubernetes to scale the number of replicas of
deployments in response to configured metrics.

This feature conflicts with the operators ability to manage the number of static
replicas to create for each deployment.

The use of the settings below will tell the operator to not manage the replicas
field on the identified deployments even if a replicas count has been set for those
properties in the operator resource.

| Name                   | Description                               | Default |
| -----------------------| ----------------------------------------- | ------- |
| web_manage_replicas    | Indicates operator should control the     | true    |
|                        | replicas count for the web deployment.    |         |
|                        |                                           |         |
| task_manage_replicas   | Indicates operator should control the     | true    |
|                        | replicas count for the task deployment.   |         |

#### Recommended Settings for HPA

Please see the Kubernetes documentation on how to configure the horizontal pod
autoscaler.

The values for optimal HPA are cluster and need specific so general guidelines
are not available at this time.
