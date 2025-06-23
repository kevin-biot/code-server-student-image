#!/bin/bash
# course-setup.sh - Instructor setup for DevOps workshop

set -e

echo "🎓 DevOps Workshop - Instructor Course Setup"
echo "============================================="

# Check cluster-admin permissions
if ! oc auth can-i create clustertasks --all-namespaces >/dev/null 2>&1; then
    echo "❌ Error: cluster-admin permissions required for course setup"
    echo "Please ensure you're logged in as cluster-admin"
    exit 1
fi

echo "✅ Cluster-admin permissions verified"

# Install shared ClusterTasks for all students
echo "📋 Installing shared Tekton ClusterTasks..."
WORKSHOP_REPO_PATH="${1:-/Users/kevinbrown/devops-test/java-webapp}"

if [[ ! -d "$WORKSHOP_REPO_PATH/tekton/clustertasks" ]]; then
    echo "❌ ClusterTasks not found at: $WORKSHOP_REPO_PATH/tekton/clustertasks"
    echo "Please specify correct path: $0 /path/to/java-webapp"
    exit 1
fi

cd "$WORKSHOP_REPO_PATH"
oc apply -f tekton/clustertasks/

echo "📦 Installing Shipwright ClusterBuildStrategies..."
oc apply -f shipwright/build/buildstrategy_buildah_shipwright_managed_push_cr.yaml

echo "✅ ClusterTasks installed:"
tkn clustertask list | grep -E "(git-clone|maven-build|war-sanity-check)"

echo "✅ ClusterBuildStrategies installed:"
oc get clusterbuildstrategy buildah-shipwright-managed-push

# Grant students read access to ClusterBuildStrategies
echo "🔐 Configuring Shipwright RBAC for students..."
oc adm policy add-cluster-role-to-user view system:serviceaccounts

echo "✅ Students can now access ClusterBuildStrategies"

# Build the code-server image
echo "🏗️ Building code-server student image..."
cd /Users/kevinbrown/code-server-student-image
./build-and-verify.sh

echo "🎉 Course setup complete!"
echo ""
echo "📚 Ready to deploy students:"
echo "  ./deploy-students.sh -n 20 -d apps-crc.testing --console-access"
echo ""
echo "🔍 Test student experience:"
echo "  ./test-deployment.sh <student-name>"
