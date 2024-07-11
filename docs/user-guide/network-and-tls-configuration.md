### Network and TLS Configuration

#### Service Type

If the `service_type` is not specified, the `ClusterIP` service will be used for your AWX Tower service.

The `service_type` supported options are: `ClusterIP`, `LoadBalancer` and `NodePort`.

The following variables are customizable for any `service_type`

| Name                | Description             | Default      |
| ------------------- | ----------------------- | ------------ |
| service_labels      | Add custom labels       | Empty string |
| service_annotations | Add service annotations | Empty string |

```yaml
---
spec:
  ...
  service_type: ClusterIP
  service_annotations: |
    environment: testing
  service_labels: |
    environment: testing
```

  * LoadBalancer

The following variables are customizable only when `service_type=LoadBalancer`

| Name                  | Description                              | Default |
| --------------------- | ---------------------------------------- | ------- |
| loadbalancer_protocol | Protocol to use for Loadbalancer ingress | http    |
| loadbalancer_port     | Port used for Loadbalancer ingress       | 80      |
| loadbalancer_ip       | Assign Loadbalancer IP                   | ''      |
| loadbalancer_class    | LoadBalancer class to use                | ''      |

```yaml
---
spec:
  ...
  service_type: LoadBalancer
  loadbalancer_ip: '192.168.10.25'
  loadbalancer_protocol: https
  loadbalancer_port: 443
  loadbalancer_class: service.k8s.aws/nlb
  service_annotations: |
    environment: testing
  service_labels: |
    environment: testing
```

When setting up a Load Balancer for HTTPS you will be required to set the `loadbalancer_port` to move the port away from `80`.

The HTTPS Load Balancer also uses SSL termination at the Load Balancer level and will offload traffic to AWX over HTTP.

  * NodePort

The following variables are customizable only when `service_type=NodePort`

| Name          | Description            | Default |
| ------------- | ---------------------- | ------- |
| nodeport_port | Port used for NodePort | 30080   |

```yaml
---
spec:
  ...
  service_type: NodePort
  nodeport_port: 30080
```
#### Ingress Type

By default, the AWX operator is not opinionated and won't force a specific ingress type on you. So, when the `ingress_type` is not specified, it will default to `none` and nothing ingress-wise will be created.

The `ingress_type` supported options are: `none`, `ingress` and `route`. To toggle between these options, you can add the following to your AWX CRD:

  * None

```yaml
---
spec:
  ...
  ingress_type: none
```

  * Generic Ingress Controller

The following variables are customizable when `ingress_type=ingress`. The `ingress` type creates an Ingress resource as [documented](https://kubernetes.io/docs/concepts/services-networking/ingress/) which can be shared with many other Ingress Controllers as [listed](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).

| Name                               | Description                                                                        | Default                     |
| ---------------------------------- | ---------------------------------------------------------------------------------- | --------------------------- |
| ingress_annotations                | Ingress annotations                                                                | Empty string                |
| ingress_tls_secret _(deprecated)_  | Secret that contains the TLS information                                           | Empty string                |
| ingress_class_name                 | Define the ingress class name                                                      | Cluster default             |
| hostname _(deprecated)_            | Define the FQDN                                                                    | {{ meta.name }}.example.com |
| ingress_hosts                      | Define one or multiple FQDN with optional Secret that contains the TLS information | Empty string                |
| ingress_path                       | Define the ingress path to the service                                             | /                           |
| ingress_path_type                  | Define the type of the path (for LBs)                                              | Prefix                      |
| ingress_api_version                | Define the Ingress resource apiVersion                                             | 'networking.k8s.io/v1'      |

```yaml
---
spec:
  ...
  ingress_type: ingress
  ingress_hosts:
    - hostname: awx-demo.example.com
    - hostname: awx-demo.sample.com
      tls_secret: sample-tls-secret
  ingress_annotations: |
    environment: testing
```

##### Specialized Ingress Controller configuration

Some Ingress Controllers need a special configuration to fully support AWX, add the following value with the `ingress_controller` variable, if you are using one of these:

| Ingress Controller name               | value   |
| ------------------------------------- | ------- |
| [Contour](https://projectcontour.io/) | contour |

```yaml
---
spec:
  ...
  ingress_type: ingress
  ingress_hosts:
    - hostname: awx-demo.example.com
    - hostname: awx-demo.sample.com
      tls_secret: sample-tls-secret
  ingress_controller: contour
```

  * Route

The following variables are customizable when `ingress_type=route`

| Name                            | Description                                   | Default                                                 |
| ------------------------------- | --------------------------------------------- | ------------------------------------------------------- |
| route_host                      | Common name the route answers for             | `<instance-name>-<namespace>-<routerCanonicalHostname>` |
| route_tls_termination_mechanism | TLS Termination mechanism (Edge, Passthrough) | Edge                                                    |
| route_tls_secret                | Secret that contains the TLS information      | Empty string                                            |
| route_api_version               | Define the Route resource apiVersion          | 'route.openshift.io/v1'                                 |

```yaml
---
spec:
  ...
  ingress_type: route
  route_host: awx-demo.example.com
  route_tls_termination_mechanism: Passthrough
  route_tls_secret: custom-route-tls-secret-name
```
