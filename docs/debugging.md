# Iterating on the installer without deploying the operator

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
