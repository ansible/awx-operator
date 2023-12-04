### Basic Install

After cloning this repository, you must choose the tag to run:
```sh
git clone git@github.com:ansible/awx-operator.git
cd awx-operator
git tag
git checkout tags/<tag>

# For instance:
git checkout tags/2.7.2
```

If you work from a fork and made modifications since the tag was issued, you must provide the VERSION number to deploy. Otherwise the operator will get stuck in "ImagePullBackOff" state:

```sh
export VERSION=<tag>

# For instance:
export VERSION=2.7.2
```

Once you have a running Kubernetes cluster, you can deploy AWX Operator into your cluster using [Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/). Since kubectl version 1.14 kustomize functionality is built-in (otherwise, follow the instructions here to install the latest version of Kustomize: https://kubectl.docs.kubernetes.io/installation/kustomize/ )

> Some things may need to be configured slightly differently for different Kubernetes flavors for the networking aspects. When installing on Kind, see the [kind install docs](./kind-install.md) for more details.

There is a make target you can run:
```
make deploy
```

If you have a custom operator image you have built, you can specify it with:
```
IMG=quay.io/$YOURNAMESPACE/awx-operator:$YOURTAG make deploy
```

Otherwise, you can manually create a file called `kustomization.yaml` with the following content:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases
  - github.com/ansible/awx-operator/config/default?ref=<tag>

# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator
    newTag: <tag>

# Specify a custom namespace in which to install AWX
namespace: awx
```

> **TIP:** If you need to change any of the default settings for the operator (such as resources.limits), you can add [patches](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/) at the bottom of your kustomization.yaml file.

Install the manifests by running this:

```
$ kubectl apply -k .
namespace/awx created
customresourcedefinition.apiextensions.k8s.io/awxbackups.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxrestores.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxs.awx.ansible.com created
serviceaccount/awx-operator-controller-manager created
role.rbac.authorization.k8s.io/awx-operator-awx-manager-role created
role.rbac.authorization.k8s.io/awx-operator-leader-election-role created
clusterrole.rbac.authorization.k8s.io/awx-operator-metrics-reader created
clusterrole.rbac.authorization.k8s.io/awx-operator-proxy-role created
rolebinding.rbac.authorization.k8s.io/awx-operator-awx-manager-rolebinding created
rolebinding.rbac.authorization.k8s.io/awx-operator-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/awx-operator-proxy-rolebinding created
configmap/awx-operator-awx-manager-config created
service/awx-operator-controller-manager-metrics-service created
deployment.apps/awx-operator-controller-manager created
```

Wait a bit and you should have the `awx-operator` running:

```
$ kubectl get pods -n awx
NAME                                               READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-66ccd8f997-rhd4z   2/2     Running   0          11s
```

So we don't have to keep repeating `-n awx`, let's set the current namespace for `kubectl`:

```
$ kubectl config set-context --current --namespace=awx
```

Next, create a file named `awx-demo.yml` in the same folder with the suggested content below. The `metadata.name` you provide will be the name of the resulting AWX deployment.

**Note:** If you deploy more than one AWX instance to the same namespace, be sure to use unique names.

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
```

> It may make sense to create and specify your own secret key for your deployment so that if the k8s secret gets deleted, it can be re-created if needed.  If it is not provided, one will be auto-generated, but cannot be recovered if lost. Read more [here](../user-guide/admin-user-account-configuration.md#secret-key-configuration).

If you are on Openshift, you can take advantage of Routes by specifying the following your spec. This will automatically create a Route for you with a custom hostname. This can be found on the Route section of the Openshift Console.

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: clusterip
  ingress_type: Route
```


Make sure to add this new file to the list of "resources" in your `kustomization.yaml` file:

```yaml
...
resources:
  - github.com/ansible/awx-operator/config/default?ref=<tag>
  # Add this extra line:
  - awx-demo.yml
...
```

Finally, apply the changes to create the AWX instance in your cluster:

```
kubectl apply -k .
```

After a few minutes, the new AWX instance will be deployed. You can look at the operator pod logs in order to know where the installation process is at:

```
$ kubectl logs -f deployments/awx-operator-controller-manager -c awx-manager
```

After a few seconds, you should see the operator begin to create new resources:

```
$ kubectl get pods -l "app.kubernetes.io/managed-by=awx-operator"
NAME                        READY   STATUS    RESTARTS   AGE
awx-demo-77d96f88d5-pnhr8   4/4     Running   0          3m24s
awx-demo-postgres-0         1/1     Running   0          3m34s

$ kubectl get svc -l "app.kubernetes.io/managed-by=awx-operator"
NAME                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
awx-demo-postgres   ClusterIP   None           <none>        5432/TCP       4m4s
awx-demo-service    NodePort    10.109.40.38   <none>        80:31006/TCP   3m56s
```

Once deployed, the AWX instance will be accessible by running:

```
$ minikube service -n awx awx-demo-service --url
```

By default, the admin user is `admin` and the password is available in the `<resourcename>-admin-password` secret. To retrieve the admin password, run:

```
$ kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode ; echo
yDL2Cx5Za94g9MvBP6B73nzVLlmfgPjR
```

You just completed the most basic install of an AWX instance via this operator. Congratulations!!!

For an example using the Nginx Ingress Controller in Minikube, don't miss our [demo video](https://asciinema.org/a/416946).
