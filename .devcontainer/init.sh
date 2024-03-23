# #!/usr/bin/bash

# # # DNF Install
# # dnf install -y openssl make git

# # Install oc and kubectl
# curl -sSL -o /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz \
#     && tar zxf /tmp/oc.tar.gz \
#     && mv oc /usr/local/bin/oc \
#     && mv kubectl /usr/local/bin/kubectl

# # Install krew
# (
#   set -x; cd "$(mktemp -d)" &&
#   OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
#   ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
#   KREW="krew-${OS}_${ARCH}" &&
#   curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
#   tar zxvf "${KREW}.tar.gz" &&
#   pwd &&
#   ./"${KREW}" install krew
# )

# # Add krew to path in bashrc
# echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> /root/.bashrc

# # Install krew plugins
# # /root/.krew/bin/kubectl-krew install ns ctx

# # Install requirements
# ansible-galaxy collection install -r requirements.yml --forcek