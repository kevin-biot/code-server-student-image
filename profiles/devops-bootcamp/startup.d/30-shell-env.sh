#!/bin/bash
# 30-shell-env.sh - Configure shell environment for DevOps bootcamp

# Add Pulumi env vars to bashrc
cat >> /home/coder/.bashrc << 'BASHRC'
export PULUMI_SKIP_UPDATE_CHECK=true
export PULUMI_SKIP_CONFIRMATIONS=true
BASHRC

# Add Pulumi passphrase (from runtime env)
echo "export PULUMI_CONFIG_PASSPHRASE=\"${PULUMI_CONFIG_PASSPHRASE:-}\"" >> /home/coder/.bashrc

# Add ArgoCD env vars if set
if [ -n "$ARGOCD_SERVER" ]; then
    echo "export ARGOCD_SERVER=\"$ARGOCD_SERVER\"" >> /home/coder/.bashrc
    echo "export ARGOCD_OPTS=\"${ARGOCD_OPTS:---insecure --grpc-web}\"" >> /home/coder/.bashrc
fi
