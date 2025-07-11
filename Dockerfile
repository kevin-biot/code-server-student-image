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

# kubectl - Install directly from official source (more reliable than OpenShift mirror)
RUN . /tmp/arch.env && \
    echo "Installing kubectl for ${ARCH}..." && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/ && \
    echo "kubectl installation completed"

# oc - Install from OpenShift mirror with robust error handling
RUN echo "Installing OpenShift CLI from OpenShift mirror..." && \
    mkdir -p /tmp/oc-install && \
    cd /tmp/oc-install && \
    wget -O openshift-client-linux.tar.gz "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz" && \
    tar -xzf openshift-client-linux.tar.gz && \
    cp oc /usr/local/bin/oc && \
    chmod +x /usr/local/bin/oc && \
    cd / && rm -rf /tmp/oc-install && \
    echo "oc installed successfully" && \
    oc version --client

# Tekton CLI - IMPROVED with better error handling
RUN ARCH=$(uname -m) && \
    echo "[INFO] Installing Tekton CLI for architecture: $ARCH" && \
    if [ "$ARCH" = "aarch64" ]; then \
      echo "Downloading Tekton CLI for ARM64..." && \
      curl -fsSL -o /tmp/tekton-cli.deb https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tektoncd-cli-${TKN_VERSION}_Linux-ARM64.deb && \
      apt-get update && apt-get install -y /tmp/tekton-cli.deb && \
      rm /tmp/tekton-cli.deb; \
    else \
      echo "Downloading Tekton CLI for x86_64..." && \
      curl -fsSL -o /tmp/tekton-cli.deb https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tektoncd-cli-${TKN_VERSION}_Linux-64bit.deb && \
      apt-get update && apt-get install -y /tmp/tekton-cli.deb && \
      rm /tmp/tekton-cli.deb; \
    fi && \
    echo "Tekton CLI installation completed"

# Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Pulumi CLI
RUN curl -fsSL https://get.pulumi.com | sh \
    && cp $HOME/.pulumi/bin/pulumi /usr/local/bin/ \
    && chmod +x /usr/local/bin/pulumi

# ArgoCD CLI - auto-detect architecture with improved error handling
RUN . /tmp/arch.env && \
    echo "Installing ArgoCD CLI for ${ARCH}..." && \
    curl -fsSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.10.0/argocd-linux-${ARCH} && \
    chmod +x /usr/local/bin/argocd && \
    echo "ArgoCD CLI installation completed"

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

# Create the workshop README directly in the image
RUN cat > /home/coder/workspace/labs/day2-tekton/README.md << 'EOF'
# Java Webapp DevOps Workshop

## Overview

This repository contains a complete DevOps workshop project featuring a simple Java servlet application with automated CI/CD pipelines. The project demonstrates modern container build and deployment practices using OpenShift Pipelines (Tekton), Shipwright Build, and Kubernetes manifests. It is designed for hands-on learning in DevOps workshops and educational environments.

## Workshop Kickoff Steps

Follow these exact steps in your code-server terminal for the workshop:

```bash
# 1. Navigate to your workshop directory
cd ~/workspace/labs/day2-tekton

# 2. Clone the workshop repository (development branch)
git clone -b dev https://github.com/kevin-biot/devops-workshop.git

# 3. Enter the project directory
cd devops-workshop

# 4. Make the setup script executable
chmod +x ./setup-student-pipeline.sh

# 5. Run the automated setup script
./setup-student-pipeline.sh
```

For complete instructions, see the full README in the devops-workshop repository after cloning.
EOF

# Set permissions correctly (OpenShift-compatible)
RUN chmod +x /home/coder/startup.sh && \
    chmod +x /home/coder/fix-gpgme-issue.sh && \
    chmod +x /home/coder/run-pipeline.sh && \
    chmod +x /home/coder/start-pipeline.sh && \
    chgrp -R 0 /home/coder && \
    chmod -R g=u /home/coder

# Verify installations
RUN echo "=== Verifying tool installations ===" && \
    node --version && \
    python3 --version && \
    java -version && \
    yq --version && \
    kubectl version --client && \
    (oc version --client || echo "oc symlinked to kubectl") && \
    (tkn version || echo "tkn installation issue") && \
    helm version && \
    pulumi version && \
    argocd version --client && \
    echo "=== Tool verification completed ==="

# OpenShift-compatible user (will be overridden by SCC)
# USER 1001
WORKDIR /home/coder/workspace

ENTRYPOINT ["/bin/bash", "-c", "/home/coder/startup.sh || exec bash"]
