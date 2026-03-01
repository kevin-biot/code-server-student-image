#!/bin/bash
# 00-base-setup.sh - Create directory structure for Java dev profile

mkdir -p /home/coder/workspace/projects \
         /home/coder/workspace/labs \
         /home/coder/workspace/examples/java \
         /home/coder/workspace/examples/kubernetes

# Set JAVA_HOME for tool-pack java
if [ -d /opt/tool-packs/java/jdk ]; then
    export JAVA_HOME=/opt/tool-packs/java/jdk
    echo "export JAVA_HOME=/opt/tool-packs/java/jdk" >> /home/coder/.bashrc
fi

# Create default kube config
mkdir -p /home/coder/.kube
cat > /home/coder/.kube/config << EOF
apiVersion: v1
kind: Config
current-context: default
contexts:
- context:
    cluster: ""
    namespace: $STUDENT_NAMESPACE
    user: ""
  name: default
EOF
