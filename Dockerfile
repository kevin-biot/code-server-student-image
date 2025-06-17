FROM ghcr.io/coder/code-server:latest

ARG ARCH=arm64
ENV TOOL_ARCH=${ARCH}

USER root

# Install core development tools and runtimes
RUN apt-get update && apt-get install -y \
    git vim nano unzip curl wget tree htop procps \
    build-essential \
    python3 python3-pip python3-venv \
    nodejs npm \
    openjdk-17-jdk maven gradle \
    docker.io \
    netcat-openbsd telnet dnsutils \
    jq \
    bash-completion \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- CLI Tools Section (Darwin ARM64 compatible) ---

# yq for YAML processing
RUN wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_darwin_arm64 \
    && chmod +x /usr/local/bin/yq

# kubectl and oc CLI (darwin-arm64)
RUN curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-mac-arm64.tar.gz \
    && tar -xzvf openshift-client-mac-arm64.tar.gz -C /usr/local/bin oc kubectl \
    && rm openshift-client-mac-arm64.tar.gz

# Tekton CLI
RUN curl -LO https://github.com/tektoncd/cli/releases/download/v0.40.0/tkn_darwin_arm64.tar.gz \
    && tar -xzf tkn_darwin_arm64.tar.gz -C /usr/local/bin tkn \
    && rm tkn_darwin_arm64.tar.gz \
    && chmod +x /usr/local/bin/tkn

# Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Pulumi
RUN curl -fsSL https://get.pulumi.com | sh \
    && cp /root/.pulumi/bin/pulumi /usr/local/bin/ \
    && chmod +x /usr/local/bin/pulumi

# ArgoCD CLI
RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.10.0/argocd-darwin-arm64 \
    && chmod +x /usr/local/bin/argocd

# --- Diagnostics Block ---
RUN echo "[INFO] Dumping tool versions for verification:" && \
    node -v && npm -v && \
    python3 --version && pip3 --version && \
    java -version && \
    mvn -v && gradle -v && \
    yq --version || echo "yq missing" && \
    oc version --client || echo "oc missing" && \
    kubectl version --client || echo "kubectl missing" && \
    tkn version || echo "tkn missing" && \
    argocd version || echo "argocd missing" && \
    pulumi version || echo "pulumi missing"

# VS Code Extensions
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

# Directory structure
RUN mkdir -p /home/coder/workspace/projects \
    /home/coder/workspace/labs/day1-pulumi \
    /home/coder/workspace/labs/day2-tekton \
    /home/coder/workspace/labs/day3-gitops \
    /home/coder/workspace/examples \
    /home/coder/workspace/templates \
    /home/coder/.local/bin

# Bash completions
RUN echo 'source <(oc completion bash)' >> /home/coder/.bashrc \
    && echo 'source <(kubectl completion bash)' >> /home/coder/.bashrc \
    && echo 'source <(tkn completion bash)' >> /home/coder/.bashrc \
    && echo 'source <(helm completion bash)' >> /home/coder/.bashrc \
    && echo 'source <(argocd completion bash)' >> /home/coder/.bashrc \
    && echo 'alias k=kubectl' >> /home/coder/.bashrc \
    && echo 'complete -F __start_kubectl k' >> /home/coder/.bashrc

# Git config template and startup script
COPY --chown=1001:1001 gitconfig-template /home/coder/.gitconfig-template
COPY --chown=1001:1001 startup.sh /home/coder/startup.sh
RUN chmod +x /home/coder/startup.sh

# Templates
COPY --chown=1001:1001 workshop-templates/ /home/coder/workspace/templates/ || true

# Fix ownership
RUN chown -R 1001:1001 /home/coder && chmod -R 755 /home/coder

# Environment variables
ENV HOME=/home/coder
ENV XDG_CONFIG_HOME=/home/coder/.config
ENV XDG_DATA_HOME=/home/coder/.local/share
ENV SHELL=/bin/bash
ENV STUDENT_NAMESPACE=""
ENV PULUMI_SKIP_UPDATE_CHECK=true
ENV PULUMI_SKIP_CONFIRMATIONS=true

USER 1001
WORKDIR /home/coder/workspace

# Resilient startup fallback
ENTRYPOINT ["/bin/bash", "-c", "/home/coder/startup.sh || exec bash"]
