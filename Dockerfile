FROM ghcr.io/coder/code-server:latest

USER root

# Install comprehensive development tools
RUN apt-get update && apt-get install -y \
    # Core development tools
    git vim nano unzip curl wget \
    build-essential \
    # Language runtimes
    python3 python3-pip python3-venv \
    nodejs npm \
    openjdk-17-jdk maven gradle \
    # DevOps tools
    docker.io \
    # Utilities
    tree htop procps \
    # Network tools for debugging
    netcat-openbsd telnet \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install kubectl and oc CLI
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl && mv kubectl /usr/local/bin/ \
    && curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz \
    | tar -xzC /usr/local/bin/ oc kubectl

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install additional Python packages commonly used in courses
RUN pip3 install --no-cache-dir \
    flask \
    requests \
    pytest \
    black \
    flake8

# Install useful VS Code extensions
RUN --mount=type=tmpfs,target=/tmp \
    code-server --install-extension ms-python.python \
    --install-extension ms-vscode.vscode-json \
    --install-extension redhat.vscode-yaml \
    --install-extension ms-kubernetes-tools.vscode-kubernetes-tools \
    --install-extension ms-vscode.vscode-docker

# Create workspace directory structure
RUN mkdir -p /home/coder/workspace/projects \
    && mkdir -p /home/coder/workspace/labs \
    && mkdir -p /home/coder/workspace/examples

# Set up Git configuration template
COPY --chown=1001:1001 gitconfig-template /home/coder/.gitconfig-template

# Create startup script for user customization
COPY --chown=1001:1001 startup.sh /home/coder/startup.sh
RUN chmod +x /home/coder/startup.sh

# Ensure proper ownership and permissions
RUN chown -R 1001:1001 /home/coder \
    && chmod -R 755 /home/coder

# Environment variables
ENV HOME=/home/coder
ENV XDG_CONFIG_HOME=/home/coder/.config
ENV XDG_DATA_HOME=/home/coder/.local/share
ENV SHELL=/bin/bash

# Switch to non-root user
USER 1001

# Set working directory
WORKDIR /home/coder/workspace

# Custom entrypoint to run startup script
ENTRYPOINT ["/home/coder/startup.sh"]
