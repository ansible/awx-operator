ARG BASEIMAGE
FROM ${BASEIMAGE}
USER 0

RUN yum install -y python-devel gcc libffi-devel
RUN pip install molecule==2.20.1

ARG NAMESPACEDMAN
ADD $NAMESPACEDMAN /namespaced.yaml
ADD build/test-framework/ansible-test.sh /ansible-test.sh
RUN chmod +x /ansible-test.sh
USER 1001
ADD . /opt/ansible/project
