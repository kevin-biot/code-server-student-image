#!/bin/bash
# 00-base-setup.sh - Create directory structure for cloud-native profile

mkdir -p /home/coder/workspace/projects \
         /home/coder/workspace/labs \
         /home/coder/workspace/examples/kubernetes \
         /home/coder/workspace/examples/helm \
         /home/coder/workspace/examples/python

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
