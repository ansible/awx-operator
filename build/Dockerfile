FROM quay.io/operator-framework/ansible-operator:v0.12.0

# Install kubectl.
COPY --from=lachlanevenson/k8s-kubectl:v1.16.2 /usr/local/bin/kubectl /usr/local/bin/kubectl

COPY watches.yaml ${HOME}/watches.yaml

COPY main.yml ${HOME}/main.yml
COPY roles/ ${HOME}/roles/
