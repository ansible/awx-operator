FROM quay.io/operator-framework/ansible-operator:v0.19.4

# Install Ansible requirements.
COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml

COPY main.yml ${HOME}/main.yml
COPY roles/ ${HOME}/roles/
