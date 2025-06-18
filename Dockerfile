FROM ghcr.io/coder/code-server:latest

ARG ARCH=arm64
ENV TOOL_ARCH=${ARCH}
ARG TKN_VERSION=0.41.0
ENV HOME=/home/coder
ENV XDG_CONFIG_HOME=/home/coder/.config
ENV XDG_DATA_HOME=/home/coder/.local/share
ENV SHELL=/bin/bash
ENV STUDENT_NAMESPACE=""
ENV PULUMI_SKIP_UPDATE_CHECK=true
ENV PULUMI_SKIP_CONFIRMATIONS=true

USER root

# Core dev tools
RUN apt-get update && apt-get install -y \
    git vim nano unzip curl wget tree htop procps \
    build-essential \
    python3 python3-pip python3-venv \
    nodejs npm \
    openjdk-17-jdk maven gradle \
    netcat-openbsd dnsutils \
    jq bash-completion && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# yq (YAML processor)
RUN wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_linux_${ARCH} \
    && chmod +x /usr/local/bin/yq

# oc and kubectl
RUN curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-${ARCH}.tar.gz \
    && tar -xzvf openshift-client-linux-${ARCH}.tar.gz -C /usr/local/bin oc kubectl \
    && rm openshift-client-linux-${ARCH}.tar.gz

# Tekton CLI
RUN ARCH=$(uname -m) && \
    echo "[INFO] Detected architecture: $ARCH" && \
    if [ "$ARCH" = "aarch64" ]; then \
      curl -LO https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tektoncd-cli-${TKN_VERSION}_Linux-ARM64.deb && \
      apt-get update && apt-get install -y ./tektoncd-cli-${TKN_VERSION}_Linux-ARM64.deb && \
      rm tektoncd-cli-${TKN_VERSION}_Linux-ARM64.deb; \
    else \
      curl -LO https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tektoncd-cli-${TKN_VERSION}_Linux-64bit.deb && \
      apt-get update && apt-get install -y ./tektoncd-cli-${TKN_VERSION}_Linux-64bit.deb && \
      rm tektoncd-cli-${TKN_VERSION}_Linux-64bit.deb; \
    fi

# Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Pulumi CLI
RUN curl -fsSL https://get.pulumi.com | sh \
    && cp $HOME/.pulumi/bin/pulumi /usr/local/bin/ \
    && chmod +x /usr/local/bin/pulumi

# ArgoCD CLI
RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.10.0/argocd-linux-${ARCH} \
    && chmod +x /usr/local/bin/argocd

# Install VS Code extensions
RUN HOME=/home/coder code-server \
    --user-data-dir /home/coder/.local/share/code-server \
    --install-extension ms-python.python \
    --install-extension redhat.vscode-yaml \
    --install-extension ms-kubernetes-tools.vscode-kubernetes-tools \
    --install-extension ms-azuretools.vscode-docker \
    --install-extension vscjava.vscode-java-pack \
    --install-extension ms-vscode.vscode-typescript-next \
    --install-extension esbenp.prettier-vscode \
    --install-extension redhat.vscode-xml

# Create expected directory structure
RUN mkdir -p /home/coder/workspace/projects \
             /home/coder/workspace/labs/day1-pulumi \
             /home/coder/workspace/labs/day2-tekton \
             /home/coder/workspace/labs/day3-gitops \
             /home/coder/workspace/examples \
             /home/coder/workspace/templates \
             /home/coder/.local/bin

# Copy templates and config - ensure ownership
COPY gitconfig-template /home/coder/.gitconfig-template
COPY startup.sh /home/coder/startup.sh
COPY workshop-templates/ /home/coder/workspace/templates/

# Set permissions correctly (non-root safe)
RUN chmod +x /home/coder/startup.sh && \
    chown -R 1001:0 /home/coder && \
    chmod -R 755 /home/coder

# Final user switch
USER 1001
WORKDIR /home/coder/workspace

ENTRYPOINT ["/bin/bash", "-c", "/home/coder/startup.sh || exec bash"]
