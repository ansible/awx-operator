#### Scaling the Web and Task Pods independently

You can scale replicas up or down for each deployment by using the `web_replicas` or `task_replicas` respectively. You can scale all pods across both deployments by using `replicas` as well. The logic behind these CRD keys acts as such:

- If you specify the `replicas` field, the key passed will scale both the `web` and `task` replicas to the same number.
- If `web_replicas` or `task_replicas` is ever passed, it will override the existing `replicas` field on the specific deployment with the new key value.

These new replicas can be constrained in a similar manner to previous single deployments by appending the particular deployment name in front of the constraint used. More about those new constraints can be found in the [Assigning AWX pods to specific nodes](./assigning-awx-pods-to-specific-nodes.md) page.

##### Horizontal Pod Autoscaling

The operator is capable of working with Kubernete's HPA capabilities.  See [Horizontal Pod Autoscaler](./horizontal-pod-autoscaler.md)
documentation for more information.
