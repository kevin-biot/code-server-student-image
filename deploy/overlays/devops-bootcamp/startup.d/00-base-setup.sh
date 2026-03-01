#!/bin/bash
# 00-base-setup.sh - Create directory structure and set up Pulumi environment

# Create workspace directories
mkdir -p /home/coder/workspace/projects \
         /home/coder/workspace/labs/day1-pulumi \
         /home/coder/workspace/labs/day2-tekton \
         /home/coder/workspace/labs/day3-gitops \
         /home/coder/workspace/examples/{kubernetes,tekton,pulumi,shipwright,argocd} \
         /home/coder/workspace/templates

# Set up Pulumi environment
export PULUMI_CONFIG_PASSPHRASE="${PULUMI_CONFIG_PASSPHRASE:-}"
export PULUMI_SKIP_UPDATE_CHECK=true
export PULUMI_SKIP_CONFIRMATIONS=true

# Create default kube config with student namespace
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
