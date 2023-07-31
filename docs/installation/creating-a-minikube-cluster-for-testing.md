### Creating a minikube cluster for testing

If you do not have an existing cluster, the `awx-operator` can be deployed on a [Minikube](https://minikube.sigs.k8s.io/docs/) cluster for testing purposes. Due to different OS and hardware environments, please refer to the official Minikube documentation for further information.

```
$ minikube start --cpus=4 --memory=6g --addons=ingress
😄  minikube v1.23.2 on Fedora 34
✨  Using the docker driver based on existing profile
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🏃  Updating the running docker "minikube" container ...
🐳  Preparing Kubernetes v1.22.2 on Docker 20.10.8 ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
    ▪ Using image k8s.gcr.io/ingress-nginx/controller:v1.0.0-beta.3
    ▪ Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0
    ▪ Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0
🔎  Verifying ingress addon...
🌟  Enabled addons: storage-provisioner, default-storageclass, ingress
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

Once Minikube is deployed, check if the node(s) and `kube-apiserver` communication is working as expected.

```
$ minikube kubectl -- get nodes
NAME       STATUS   ROLES                  AGE    VERSION
minikube   Ready    control-plane,master   113s   v1.22.2

$ minikube kubectl -- get pods -A
NAMESPACE       NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx   ingress-nginx-admission-create--1-kk67h     0/1     Completed   0          2m1s
ingress-nginx   ingress-nginx-admission-patch--1-7mp2r      0/1     Completed   1          2m1s
ingress-nginx   ingress-nginx-controller-69bdbc4d57-bmwg8   1/1     Running     0          2m
kube-system     coredns-78fcd69978-q7nmx                    1/1     Running     0          2m
kube-system     etcd-minikube                               1/1     Running     0          2m12s
kube-system     kube-apiserver-minikube                     1/1     Running     0          2m16s
kube-system     kube-controller-manager-minikube            1/1     Running     0          2m12s
kube-system     kube-proxy-5mmnw                            1/1     Running     0          2m1s
kube-system     kube-scheduler-minikube                     1/1     Running     0          2m15s
kube-system     storage-provisioner                         1/1     Running     0          2m11s
```

It is not required for `kubectl` to be separately installed since it comes already wrapped inside minikube. As demonstrated above, simply prefix `minikube kubectl --` before kubectl command, i.e. `kubectl get nodes` would become `minikube kubectl -- get nodes`

Let's create an alias for easier usage:

```
$ alias kubectl="minikube kubectl --"
```
