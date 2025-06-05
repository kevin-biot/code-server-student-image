FROM ghcr.io/coder/code-server:latest

USER root

RUN apt-get update && apt-get install -y \
    git \
    vim \
    unzip \
    curl \
    gnupg \
    && curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz \
    && tar -xvzf oc.tar.gz -C /usr/local/bin && rm -f oc.tar.gz \
    && curl -LO https://github.com/tektoncd/cli/releases/download/v0.36.0/tkn_0.36.0_Linux_x86_64.tar.gz \
    && tar -xvzf tkn_0.36.0_Linux_x86_64.tar.gz -C /usr/local/bin && rm -f tkn_0.36.0_Linux_x86_64.tar.gz \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
