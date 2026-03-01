# Base training platform image - code-server + core system tools
# Profile-specific tools are delivered via init container tool-packs
ARG CODE_SERVER_VERSION=4.109.2
FROM ghcr.io/coder/code-server:${CODE_SERVER_VERSION}

ENV HOME=/home/coder
ENV XDG_CONFIG_HOME=/home/coder/.config
ENV XDG_DATA_HOME=/home/coder/.local/share
ENV SHELL=/bin/bash
ENV STUDENT_NAMESPACE=""

USER root

# Core system tools only - language runtimes and DevOps CLIs come from tool-packs
RUN apt-get update && apt-get install -y \
    git vim nano unzip curl wget tree htop procps \
    build-essential \
    jq bash-completion \
    netcat-openbsd dnsutils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# yq (YAML processor) - auto-detect architecture
RUN ARCH=$(uname -m) && \
    case "${ARCH}" in x86_64) ARCH=amd64 ;; aarch64) ARCH=arm64 ;; esac && \
    wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_linux_${ARCH} && \
    chmod +x /usr/local/bin/yq

# Create directory structure
RUN mkdir -p /home/coder/workspace/projects \
             /home/coder/workspace/labs \
             /home/coder/workspace/examples \
             /home/coder/workspace/templates \
             /home/coder/.local/bin \
             /home/coder/startup.d \
             /opt/tool-packs/bin

# Copy base config files
COPY gitconfig-template /home/coder/.gitconfig-template
COPY startup.sh /home/coder/startup.sh

# Set permissions (OpenShift-compatible: group 0 gets user permissions)
RUN chmod +x /home/coder/startup.sh && \
    chgrp -R 0 /home/coder /opt/tool-packs && \
    chmod -R g=u /home/coder /opt/tool-packs

WORKDIR /home/coder/workspace

ENTRYPOINT ["/bin/bash", "-c", "/home/coder/startup.sh || exec bash"]
