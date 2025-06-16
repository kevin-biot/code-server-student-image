FROM ghcr.io/coder/code-server:latest

USER root

# Install comprehensive development tools
RUN apt-get update && apt-get install -y \
    # Core development tools
    git vim nano unzip curl wget tree htop procps \
    build-essential \
    # Language runtimes
    python3 python3-pip python3-venv \
    nodejs npm \
    openjdk-17-jdk maven gradle \
    # DevOps tools
    docker.io \
    # Network tools for debugging
    netcat-openbsd telnet dnsutils \
    # JSON/YAML processing
    jq \
    # Additional utilities
    bash-completion \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install yq for YAML processing
RUN wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq

# Install kubectl and oc CLI
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl && mv kubectl /usr/local/bin/ \
    && curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz \
    | tar -xzC /usr/local/bin/ oc kubectl

# Install Tekton CLI
RUN curl -LO https://github.com/tektoncd/cli/releases/latest/download/tkn_Linux_x86_64.tar.gz \
    && tar xvzf tkn_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn \
    && rm tkn_Linux_x86_64.tar.gz \
    && chmod +x /usr/local/bin/tkn

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Pulumi
RUN curl -fsSL https://get.pulumi.com | sh \
    && cp /root/.pulumi/bin/pulumi /usr/local/bin/ \
    && chmod +x /usr/local/bin/pulumi

# Install ArgoCD CLI
RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 \
    && chmod +x /usr/local/bin/argocd

# Install additional Python packages for DevOps
RUN pip3 install --no-cache-dir \
    flask \
    requests \
    pytest \
    black \
    flake8 \
    pyyaml \
    kubernetes

# Install Node.js packages for Pulumi and workshop
RUN npm install -g \
    @pulumi/kubernetes \
    @pulumi/pulumi \
    typescript \
    @types/node \
    yaml-lint \
    prettier

# Install useful VS Code extensions as the coder user
USER 1001
RUN --mount=type=tmpfs,target=/tmp \
    HOME=/home/coder code-server \
    --user-data-dir /home/coder/.local/share/code-server \
    --install-extension ms-python.python \
    --install-extension ms-vscode.vscode-json \
    --install-extension redhat.vscode-yaml \
    --install-extension ms-kubernetes-tools.vscode-kubernetes-tools \
    --install-extension ms-vscode.vscode-docker \
    --install-extension vscjava.vscode-java-pack \
    --install-extension ms-vscode.vscode-typescript-next \
    --install-extension esbenp.prettier-vscode \
    --install-extension redhat.vscode-xml
USER root

# Create comprehensive workspace directory structure
RUN mkdir -p /home/coder/workspace/projects \
    && mkdir -p /home/coder/workspace/labs/day1-pulumi \
    && mkdir -p /home/coder/workspace/labs/day2-tekton \
    && mkdir -p /home/coder/workspace/labs/day3-gitops \
    && mkdir -p /home/coder/workspace/examples \
    && mkdir -p /home/coder/workspace/templates \
    && mkdir -p /home/coder/.local/bin

# Set up shell completions
RUN echo 'source <(oc completion bash)' >> /home/coder/.bashrc \
    && echo 'source <(kubectl completion bash)' >> /home/coder/.bashrc \
    && echo 'source <(tkn completion bash)' >> /home/coder/.bashrc \
    && echo 'source <(helm completion bash)' >> /home/coder/.bashrc \
    && echo 'source <(argocd completion bash)' >> /home/coder/.bashrc \
    && echo 'alias k=kubectl' >> /home/coder/.bashrc \
    && echo 'complete -F __start_kubectl k' >> /home/coder/.bashrc

# Set up Git configuration template
COPY --chown=1001:1001 gitconfig-template /home/coder/.gitconfig-template

# Create enhanced startup script with workshop materials
COPY --chown=1001:1001 startup.sh /home/coder/startup.sh
RUN chmod +x /home/coder/startup.sh

# Copy workshop exercise templates (if they exist)
COPY --chown=1001:1001 workshop-templates/ /home/coder/workspace/templates/ || true

# Ensure proper ownership and permissions
RUN chown -R 1001:1001 /home/coder \
    && chmod -R 755 /home/coder

# Environment variables
ENV HOME=/home/coder
ENV XDG_CONFIG_HOME=/home/coder/.config
ENV XDG_DATA_HOME=/home/coder/.local/share
ENV SHELL=/bin/bash
ENV STUDENT_NAMESPACE=""
ENV PULUMI_SKIP_UPDATE_CHECK=true
ENV PULUMI_SKIP_CONFIRMATIONS=true

# Switch to non-root user
USER 1001

# Set working directory
WORKDIR /home/coder/workspace

# Custom entrypoint to run startup script
ENTRYPOINT ["/home/coder/startup.sh"]