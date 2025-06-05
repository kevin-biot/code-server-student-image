FROM ghcr.io/coder/code-server:latest

USER root

# Install core CLI tools
RUN yum install -y \
    git \
    vim \
    unzip \
    which \
    && curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz \
    && tar -xvzf oc.tar.gz -C /usr/local/bin && rm -f oc.tar.gz \
    && curl -LO https://github.com/tektoncd/cli/releases/download/v0.36.0/tkn_0.36.0_Linux_x86_64.tar.gz \
    && tar -xvzf tkn_0.36.0_Linux_x86_64.tar.gz -C /usr/local/bin && rm -f tkn_0.36.0_Linux_x86_64.tar.gz \
    && yum clean all

# Optional: Install Maven & JDK if required
RUN yum install -y maven java-17-openjdk-devel

USER coder
