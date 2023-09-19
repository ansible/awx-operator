# Debugging the AWX Operator

## General Debugging

When the operator is deploying AWX, it is running the `installer` role inside the operator container. If the AWX CR's status is `Failed`, it is often useful to look at the awx-operator container logs, which shows the output of the installer role. To see these logs, run:

```
kubectl logs deployments/awx-operator-controller-manager -c awx-manager -f
```

### Improving the Operator Logs

To show more verbose logs, set the `ANSIBLE_VERBOSITY` env var to 2 (or higher) and `ANSIBLE_DEBUG_LOGS` to `true`. We have enabled the `yaml` stdout_callback in the operator's ansible.cfg, so this will now provide nicely formatted logs. You can do this easily with the following command.

```
kubectl set env deployment/awx-operator-controller-manager ANSIBLE_VERBOSITY=2
```

> Note: Setting verbosity to 3 is quite verbose, but may have more information to help with debugging in some cases.

Furthermore, you can easily enable timing and performance metrics by copying in the ansible.cfg.dev config and rebuilding the operator image with it.

```
# Copy over custom ansible.cfg
cp files/ansible.cfg.dev files/ansible.cfg

# Build Operator image
export QUAY_USER=youruser
export TAG=dev
make docker-build docker-push IMG=quay.io/$QUAY_USER/awx-operator:$TAG

# Deploy
export NAMESPACE=awx-dev
make deploy IMG=quay.io/$QUAY_USER/awx-operator:$TAG NAMESPACE=$NAMESPACE

```

### Inspect k8s Resources

Past that, it is often useful to inspect various resources the AWX Operator manages like:
* awx
* awxbackup
* awxrestore
* pod
* deployment
* pvc
* service
* ingress
* route
* secrets
* serviceaccount

And if installing via OperatorHub and OLM:
* subscription
* csv
* installPlan
* catalogSource

To inspect these resources you can use these commands

```
# Inspecting k8s resources
kubectl describe -n <namespace> <resource> <resource-name>
kubectl get -n <namespace> <resource> <resource-name> -o yaml
kubectl logs -n <namespace> <resource> <resource-name>

# Inspecting Pods
kubectl exec -it -n <namespace> <pod> <pod-name>
```


### Configure No Log

It is possible to show task output for debugging by setting no_log to false on the AWX CR spec.
This will show output in the awx-operator logs for any failed tasks where no_log was set to true.

For example:

```
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
  no_log: false                  # <------------

```

## Iterating on the installer without deploying the operator

Go through the [normal basic install](https://github.com/ansible/awx-operator/blob/devel/README.md#basic-install) steps.

Install some dependencies:

```
$ ansible-galaxy collection install -r molecule/requirements.yml
$ pip install -r molecule/requirements.txt
```

To prevent the changes we're about to make from being overwritten, scale down any running instance of the operator:

```
$ kubectl scale deployment awx-operator-controller-manager --replicas=0
```

Create a playbook that invokes the installer role (the operator uses ansible-runner's role execution feature):

```yaml
# run.yml
---
- hosts: localhost
  roles:
    - installer
```

Create a vars file:

```yaml
# vars.yml
---
ansible_operator_meta:
  name: awx
  namespace: awx
service_type: nodeport
```
The vars file will replace the awx resource so any value that you wish to over ride using the awx resource, put in the vars file. For example, if you wish to use your own image, version and pull policy, you can specify it like below:

```yaml
# vars.yml
---
ansible_operator_meta:
  name: awx
  namespace: awx
service_type: nodeport
image: $DEV_DOCKER_TAG_BASE/awx_kube_devel
image_pull_policy: Always
image_version: $COMPOSE_TAG
```

Run the installer:

```
$ ansible-playbook run.yml -e @vars.yml -v
```

Grab the URL and admin password:

```
$ minikube service awx-service --url -n awx
$ minikube kubectl get secret awx-admin-password -- -o jsonpath="{.data.password}" | base64 --decode
LU6lTfvnkjUvDwL240kXKy1sNhjakZmT
```
