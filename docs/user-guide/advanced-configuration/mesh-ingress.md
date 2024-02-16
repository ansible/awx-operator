# Mesh Ingress

The mesh ingress allows users to peer external execution and hop nodes into the AWX control plane.
This guide focuses on how to enable and configure the mesh ingress.
For more information about remote execution and hop nodes and how to create them, refer to the [Managing Capacity With Instances](https://ansible.readthedocs.io/projects/awx/en/latest/administration/instances.html) chapter of the AWX Administration Guide.

## Prerequisites

- AWX operator version > 2.11.0
- AWX > 23.8.0

## Deploy and configure AWXMeshIngress

### On Red Hat OpenShift with operator managed Route

To deploy an mesh ingress on OpenShift create the AWXMeshIngress resource.

Example:

```yaml
---
apiVersion: awx.ansible.com/v1alpha1
kind: AWXMeshIngress
metadata:
  name: <mesh ingress name>
spec:
  deployment_name: <awx instance name>
```

### User managed Ingress

UNDER CONSTRUCTION (contribution welcome)

### Operator managed Ingress

UNDER CONSTRUCTION (contribution welcome)

### Deploy and configure AWXMeshIngress via IngressRouteTCP

UNDER CONSTRUCTION (contribution welcome)

## Validating setup of Mesh Ingress

After AWXMeshIngress has been successfully created a new Instance with the same name will show up in AWX Instance UI

![mesh ingress instance on AWX UI](mesh-ingress-instance-on-awx-ui.png)

The Instance should have at least 2 listener addresses.

In this example, the mesh ingress has two listener addresses:

- one for internal, that is used for peering to by all control nodes (top)
- one for external, that is exposed to a route so external execution nodes can peer into it (bottom))

![mesh ingress instance listener address on awx ui](mesh-ingress-instance-listener-address-on-awx-ui.png)

When selecting peer for new instance the mesh ingress instance should now be present as a option.
![peering to mesh ingress on awx ui](peering-to-mesh-ingress-on-awx-ui.png)

For more information about how to create external remote execution and hop node and configuring the mesh. See AWX Documentation on [Add a instance](https://ansible.readthedocs.io/projects/awx/en/latest/administration/instances.html#add-an-instance).

## AWXMeshIngress

AWXMeshIngress controls the deployment and configuration of mesh ingress on AWX

- **apiVersion**: awx.ansible.com/v1alpha1

- **kind**: AWXMeshIngress

- **metadata**: ([ObjectMeta](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/object-meta/#ObjectMeta))

  Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata

- **spec**: ([AWXMeshIngressSpec](#awxmeshingressspec))

  spec is the desired state of the AWXMeshIngress. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

- **status**: ([AWXMeshIngressStatus](#awxmeshingressstatus))

  status is the current state of the AWXMeshIngress. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

### AWXMeshIngressSpec

AWXMeshIngress is the description of the configuration for AWXMeshIngress.

- **deployment_name** (string), required

  Name of the AWX deployment to create the Mesh Ingress for.

- **external_hostname** (string)

  External hostname is an optional field used for specifying the external hostname defined in an user managed [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

- **external_ipaddress** (string)

  External IP Address is an optional field used for specifying the external IP address defined in an user managed [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

- **ingress_type** (string)

  Ingress type for ingress managed by the operator
  Options:
  - none (default)
  - Ingress
  - IngressRouteTCP
  - Route (default when deploy on OpenShift)

- **ingress_api_version** (string)

  API Version for ingress managed by the operator
  This parameter is ignored when ingress_type=Route

- **ingress_annotations** (string)

  Annotation on the ingress managed by the operator

- **ingress_class_name** (string)

  The name of ingress class to use instead of the cluster default. see [IngressSpec](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/ingress-v1/#IngressSpec)
  This parameter is ignored when `ingress_type=Route`

- **ingress_controller** (string)

  Special configuration for specific Ingress Controllers
  This parameter is ignored when ingress_type=Route

### AWXMeshIngressStatus

AWXMeshIngressStatus describe the current state of the AWXMeshIngress.

## AWXMeshIngressList

AWXMeshIngressList is a collection of AWXMeshIngress.

- **items** ([AWXMeshIngress](#awxmeshingress))

  items is the list of Ingress.

- **apiVersion** (string)

  APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources

- **kind** (string)

  Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds

- **metadata** ([ListMeta](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/list-meta/#ListMeta))

  Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata
