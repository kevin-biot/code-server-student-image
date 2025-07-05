#!/bin/bash
# install-workshop-infrastructure.sh - Production-ready workshop setup

set -e

NAMESPACE=${NAMESPACE:-"devops-workshop-system"}
RELEASE_NAME=${RELEASE_NAME:-"devops-workshop"}

echo "🚀 Installing DevOps Workshop Infrastructure on AWS/Production"
echo "============================================================="

# Create system namespace
oc create namespace "$NAMESPACE" --dry-run=client -o yaml | oc apply -f -

# Install via Helm (if using Helm approach)
if command -v helm >/dev/null 2>&1; then
    echo "📦 Installing via Helm..."
    helm upgrade --install "$RELEASE_NAME" ./charts/devops-workshop \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --set global.environment="production" \
        --set global.storageClass="gp3-csi" \
        --set clustertasks.enabled=true
else
    echo "📋 Installing via OpenShift manifests..."
    
    # Apply ClusterTasks
    oc apply -f infrastructure/clustertasks/
    
    # Apply RBAC for workshop
    oc apply -f infrastructure/rbac/
    
    # Apply shared resources
    oc apply -f infrastructure/shared/
fi

echo "✅ Workshop infrastructure installed"
echo "📊 Verifying ClusterTasks..."
tkn clustertask list | grep -E "(git-clone|maven-build|war-sanity-check)" || echo "❌ ClusterTasks not found"

echo "🎓 Ready for student deployments!"
