#### Container Probes
These parameters control the usage of liveness and readiness container probes for
the web and task containers.

> [!ALERT]
> All of probes are disabled by default for now, to enable it, set the *_period parameters.  For example:

```

web_liveness_period: 15
web_readiness_period: 15
task_liveness_period: 15
task_readiness_period: 15
```

#### Web / Task Container Liveness Check

The liveness probe queries the status of the supervisor daemon of the container.  The probe will fail if it
detects one of the services in a state other than "RUNNING".

| Name         | Description                        | Default |
| -------------| -----------------------------------|---------|
| web_liveness_period | Time period in seconds between each probe check.  The value of 0 disables the probe. | 0    |
| web_liveness_initial_delay | Initial delay before starting probes in seconds | 5   |
| web_liveness_failure_threshold| Number of consecutive failure events to identify failure of container | 3    |
| web_liveness_timeout | Number of seconds to wait for a probe response from container | 1    |
| task_liveness_period | Time period in seconds between each probe check.  The value of 0 disables the probe. | 0    |
| task_liveness_initial_delay | Initial delay before starting probes in seconds | 5   |
| task_liveness_failure_threshold| Number of consecutive failure events to identify failure of container | 3    |
| task_liveness_timeout | Number of seconds to wait for a probe response from container | 1    |

#### Web Container Readiness Check

This is an HTTP check against the status endpoint to confirm the system is still able to respond to web requests.

| Name         | Description                        | Default |
| -------------| ---------------------------------- | ------- |
| web_readiness_period | Time period in seconds between each probe check.  The value of 0 disables the probe. | 0    |
| web_readiness_initial_delay | Initial delay before starting probes in seconds | 5   |
| web_readiness_failure_threshold| Number of consecutive failure events to identify failure of container | 3    |
| web_readiness_timeout | Number of seconds to wait for a probe response from container | 1    |

#### Task Container Readiness Check

This is a command probe using the builtin check command of the awx-manage utility.

| Name         | Description                        | Default |
| -------------| ---------------------------------- | ------- |
| task_readiness_period | Time period in seconds between each probe check.  The value of 0 disables the probe. | 0    |
| task_readiness_initial_delay | Initial delay before starting probes in seconds | 5   |
| task_readiness_failure_threshold| Number of consecutive failure events to identify failure of container | 3    |
| task_readiness_timeout | Number of seconds to wait for a probe response from container | 1    |
