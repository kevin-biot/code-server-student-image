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

# Install core development tools and runtimes
RUN apt-get update && apt-get install -y \
    git vim nano unzip curl wget tree htop procps \
    build-essential \
    python3 python3-pip python3-venv \
    nodejs npm \
    openjdk-17-jdk maven gradle \
    docker.io \
    netcat-openbsd telnet dnsutils \
    jq bash-completion \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- CLI Tools Section ---

# yq for YAML processing (Linux ARM64/x86 universal binary)
RUN wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_linux_${ARCH} \
    && chmod +x /usr/local/bin/yq

# kubectl + oc CLI
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

# Pulumi
RUN curl -fsSL https://get.pulumi.com | sh \
    && cp $HOME/.pulumi/bin/pulumi /usr/local/bin/ \
    && chmod +x /usr/local/bin/pulumi

# ArgoCD CLI (Linux binaries)
RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.10.0/argocd-linux-${ARCH} \
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

# Workspace directory structure
RUN mkdir -p /home/coder/workspace/projects \
    /home/coder/workspace/labs/day1-pulumi \
    /home/coder/workspace/labs/day2-tekton \
    /home/coder/workspace/labs/day3-gitops \
    /home/coder/workspace/examples \
    /home/coder/workspace/templates \
    /home/coder/.local/bin

# Bash completions and aliases
RUN echo 'source <(oc completion bash)' >> /home/coder/.bashrc && \
    echo 'source <(kubectl completion bash)' >> /home/coder/.bashrc && \
    echo 'source <(tkn completion bash)' >> /home/coder/.bashrc && \
    echo 'source <(helm completion bash)' >> /home/coder/.bashrc && \
    echo 'source <(argocd completion bash)' >> /home/coder/.bashrc && \
    echo 'alias k=kubectl' >> /home/coder/.bashrc && \
    echo 'complete -F __start_kubectl k' >> /home/coder/.bashrc

# Git config template and startup script
COPY --chown=1001:1001 gitconfig-template /home/coder/.gitconfig-template
COPY --chown=1001:1001 startup.sh /home/coder/startup.sh
RUN chmod +x /home/coder/startup.sh

# Templates
COPY --chown=1001:1001 workshop-templates/ /home/coder/workspace/templates/ || true

# Final permissions and workspace
RUN chown -R 1001:1001 /home/coder && chmod -R 755 /home/coder

USER 1001
WORKDIR /home/coder/workspace

# Resilient startup
ENTRYPOINT ["/bin/bash", "-c", "/home/coder/startup.sh || exec bash"]
