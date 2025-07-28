#!/bin/bash
echo "📋 Refreshing workshop instructions for code-server environments..."

# Update Day 3 instructions from main repo
curl -s -o /tmp/ARGOCD-README.md \
  https://raw.githubusercontent.com/kevin-biot/argocd/main/docs/ARGOCD-README.md

if [ $? -eq 0 ] && [ -s /tmp/ARGOCD-README.md ]; then
    cp /tmp/ARGOCD-README.md /home/coder/workspace/labs/day3-gitops/
    chown coder:coder /home/coder/workspace/labs/day3-gitops/ARGOCD-README.md
    chmod 644 /home/coder/workspace/labs/day3-gitops/ARGOCD-README.md
    echo "✅ Day 3 instructions updated"
else
    echo "⚠️  Failed to download latest instructions"
fi
