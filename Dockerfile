# Multi-architecture Dockerfile - supports both ARM64 and AMD64
FROM ghcr.io/coder/code-server:latest

# Auto-detect architecture
RUN ARCH=$(uname -m) && \
    case "${ARCH}" in \
        x86_64) ARCH=amd64 ;; \
        aarch64) ARCH=arm64 ;; \
    esac && \
    echo "Detected architecture: ${ARCH}" && \
    echo "ARCH=${ARCH}" > /tmp/arch.env

ENV TOOL_ARCH=auto
ARG TKN_VERSION=0.41.0
ENV HOME=/home/coder
ENV XDG_CONFIG_HOME=/home/coder/.config
ENV XDG_DATA_HOME=/home/coder/.local/share
ENV SHELL=/bin/bash
ENV STUDENT_NAMESPACE=""
ENV PULUMI_SKIP_UPDATE_CHECK=true
ENV PULUMI_SKIP_CONFIRMATIONS=true
ENV PULUMI_CONFIG_PASSPHRASE="workshop123"

USER root

# Remove existing Node.js and install Node.js 20
RUN apt-get update && \
    apt-get remove -y nodejs npm && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Core dev tools (updated without nodejs npm since we installed them above)
RUN apt-get update && apt-get install -y \
    git vim nano unzip curl wget tree htop procps \
    build-essential \
    python3 python3-pip python3-venv \
    openjdk-17-jdk maven gradle \
    netcat-openbsd dnsutils \
    jq bash-completion && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Verify Node.js 20 installation
RUN node --version && npm --version

# yq (YAML processor) - auto-detect architecture
RUN . /tmp/arch.env && \
    wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_linux_${ARCH} && \
    chmod +x /usr/local/bin/yq

# oc and kubectl - auto-detect architecture
RUN . /tmp/arch.env && \
    curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-${ARCH}.tar.gz && \
    tar -xzvf openshift-client-linux-${ARCH}.tar.gz -C /usr/local/bin oc kubectl && \
    rm openshift-client-linux-${ARCH}.tar.gz

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

# ArgoCD CLI - auto-detect architecture
RUN . /tmp/arch.env && \
    curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.10.0/argocd-linux-${ARCH} && \
    chmod +x /usr/local/bin/argocd

# Install only ESSENTIAL VS Code extensions (with better error handling)
RUN HOME=/home/coder mkdir -p /home/coder/.local/share/code-server && \
    timeout 300 code-server \
    --user-data-dir /home/coder/.local/share/code-server \
    --install-extension redhat.vscode-yaml \
    --install-extension ms-vscode.vscode-typescript-next || echo "Extension installation timeout - continuing"

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
COPY fix-gpgme-issue.sh /home/coder/fix-gpgme-issue.sh
COPY run-pipeline.sh /home/coder/run-pipeline.sh
COPY start-pipeline.sh /home/coder/start-pipeline.sh
COPY STUDENT-QUICK-START.md /home/coder/STUDENT-QUICK-START.md
COPY workshop-templates/ /home/coder/workspace/templates/

# Set permissions correctly (OpenShift-compatible)
RUN chmod +x /home/coder/startup.sh && \
    chmod +x /home/coder/fix-gpgme-issue.sh && \
    chmod +x /home/coder/run-pipeline.sh && \
    chmod +x /home/coder/start-pipeline.sh && \
    chgrp -R 0 /home/coder && \
    chmod -R g=u /home/coder

# OpenShift-compatible user (will be overridden by SCC)
# USER 1001
WORKDIR /home/coder/workspace

ENTRYPOINT ["/bin/bash", "-c", "/home/coder/startup.sh || exec bash"]