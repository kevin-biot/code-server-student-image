#!/bin/bash
# instructor-setup-minimal-tekton.sh - Minimal setup for simple TaskRun approach

set -e

echo "🎓 Instructor Setup: Minimal Tekton RBAC for IaC workshop"

# Check if running as cluster admin
if ! oc auth can-i create clusterroles 2>/dev/null; then
    echo "❌ This script must be run by a cluster administrator"
    echo "💡 Please run as kubeadmin or user with cluster-admin role"
    exit 1
fi

echo "🔐 Setting up minimal RBAC for TaskRuns to trigger BuildRuns..."

# Create ClusterRole for TaskRuns to manage BuildRuns
cat << 'EOF' | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tekton-buildrun-trigger
rules:
- apiGroups: ["shipwright.io"]
  resources: ["builds", "buildruns"]
  verbs: ["get", "list", "create", "update", "patch", "watch"]
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
EOF

# Bind ClusterRole to pipeline service accounts in student namespaces
echo "🔗 Creating ClusterRoleBinding for student namespaces..."
cat << 'EOF' | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tekton-buildrun-trigger-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tekton-buildrun-trigger
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: student01
- kind: ServiceAccount
  name: pipeline
  namespace: student02
- kind: ServiceAccount
  name: pipeline
  namespace: student03
- kind: ServiceAccount
  name: pipeline
  namespace: student04
- kind: ServiceAccount
  name: pipeline
  namespace: student05
# Add more student namespaces as needed
EOF

# Also bind to default service account as fallback
cat << 'EOF' | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tekton-buildrun-trigger-default-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tekton-buildrun-trigger
subjects:
- kind: ServiceAccount
  name: default
  namespace: student01
- kind: ServiceAccount
  name: default
  namespace: student02
- kind: ServiceAccount
  name: default
  namespace: student03
- kind: ServiceAccount
  name: default
  namespace: student04
- kind: ServiceAccount
  name: default
  namespace: student05
# Add more student namespaces as needed
EOF

echo ""
echo "✅ Minimal Tekton setup complete!"
echo "📋 Students can now run their IaC workshop with:"
echo "   1. cd ~/workspace/labs/day1-pulumi"
echo "   2. git pull origin main"
echo "   3. pulumi up"
echo ""
echo "🔍 To monitor TaskRun execution:"
echo "   oc get taskruns -n <student-namespace>"
echo "   oc logs taskrun/<taskrun-name> -n <student-namespace>"
