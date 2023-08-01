#### Pods termination grace period

During deployment restarts or new rollouts, when old ReplicaSet Pods are being
terminated, the corresponding jobs which are managed (executed or controlled)
by old AWX Pods may end up in `Error` state as there is no mechanism to
transfer them to the newly spawned AWX Pods. To work around the problem one
could set `termination_grace_period_seconds` in AWX spec, which does the
following:

* It sets the corresponding
  [`terminationGracePeriodSeconds`](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination)
  Pod spec of the AWX Deployment to the value provided

  > The grace period is the duration in seconds after the processes running in
  > the pod are sent a termination signal and the time when the processes are
  > forcibly halted with a kill signal

* It adds a
  [`PreStop`](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#hook-handler-execution)
  hook script, which will keep AWX Pods in terminating state until it finished,
  up to `terminationGracePeriodSeconds`.

  > This grace period applies to the total time it takes for both the PreStop
  > hook to execute and for the Container to stop normally

  While the hook script just waits until the corresponding AWX Pod (instance)
  no longer has any managed jobs, in which case it finishes with success and
  hands over the overall Pod termination process to normal AWX processes.

One may want to set this value to the maximum duration they accept to wait for
the affected Jobs to finish. Keeping in mind that such finishing jobs may
increase Pods termination time in such situations as `kubectl rollout restart`,
AWX upgrade by the operator, or Kubernetes [API-initiated
evictions](https://kubernetes.io/docs/concepts/scheduling-eviction/api-eviction/).


| Name                             | Description                                                     | Default |
| -------------------------------- | --------------------------------------------------------------- | ------- |
| termination_grace_period_seconds | Optional duration in seconds pods needs to terminate gracefully | not set |
