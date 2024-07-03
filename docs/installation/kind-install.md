# AWX Operator on Kind

## Kind Install

Install Kind by running the following

```
# For Intel Macs
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
# For M1 / ARM Macs
[ $(uname -m) = arm64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-arm64
chmod +x ./kind
mv ./kind /some-dir-in-your-PATH/kind
```

> https://kind.sigs.k8s.io/docs/user/quick-start/


### Create the Kind cluster

Create a file called `kind.config`

```yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 32000
    hostPort: 32000
    listenAddress: "0.0.0.0" # Optional, defaults to "0.0.0.0"
    protocol: tcp # Optional, defaults to tcp
- role: worker
```

Then create a cluster using that config

```
kind create cluster --config=kind.config
```

Set cluster context for kubectl

```
kubectl cluster-info --context kind-kind
```

Install NGINX Ingress Controller

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```


## AWX

Set the namespace context

```
kubectl config set-context --current --namespace=awx
```

Checkout the tag you want to install from

```
git checkout 2.7.2
```

Create a file named `kustomization.yaml` in the root of your local awx-operator clone. Include the following:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases
  - github.com/ansible/awx-operator/config/default?ref=2.7.2

# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.7.2

# Specify a custom namespace in which to install AWX
namespace: awx
```

Run the following to apply the yaml

```
kubectl apply -k .
```


Create a file called `awx-cr.yaml` with the following contents and any configuration changes you may wish to add.

```
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
  nodeport_port: 32000
```

Create your AWX CR

```
kubectl create -f awx-cr.yaml
```

Your AWX instance should now be reacheable at http://localhost:32000/

> If you configured a custom nodeport_port, you can find it by running `kubectl -n awx get svc awx-demo-service`



## Cleanup

When you are done, you can delete all of this by running

```
kind delete cluster
```
