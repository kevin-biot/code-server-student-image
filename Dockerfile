FROM ghcr.io/coder/code-server:latest

# Switch to root to install extra packages and tools
USER root

# Create writable working directories and install tools
RUN mkdir -p /home/coder/.config /workspace && \
    chmod -R 777 /home/coder /workspace && \
    # Install packages and tools
    apt-get update && \
    apt-get install -y git vim unzip curl && \
    # Install OC CLI
    curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz && \
    tar -xzf oc.tar.gz -C /usr/local/bin --strip-components=1 && \
    rm -f oc.tar.gz && \
    # Install TKN CLI
    curl -LO https://github.com/tektoncd/cli/releases/download/v0.36.0/tkn_0.36.0_Linux_x86_64.tar.gz && \
    tar -xzf tkn_0.36.0_Linux_x86_64.tar.gz -C /usr/local/bin --strip-components=1 && \
    rm -f tkn_0.36.0_Linux_x86_64.tar.gz && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set non-root user (OpenShift-compatible)
USER 1001

# Default directory inside container
WORKDIR /home/coder

# Expose code-server port
EXPOSE 8080

# Let code-server start with default CMD
