FROM quay.io/operator-framework/ansible-operator:v1.28.1

USER 0

RUN dnf install -y openssl

USER 1001

ARG DEFAULT_AWX_VERSION
ARG OPERATOR_VERSION
ENV DEFAULT_AWX_VERSION=${DEFAULT_AWX_VERSION}
ENV OPERATOR_VERSION=${OPERATOR_VERSION}

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/

ENTRYPOINT ["/tini", "--", "/usr/local/bin/ansible-operator", "run", \
    "--watches-file=./watches.yaml", \
    "--reconcile-period=0s" \
    ]
