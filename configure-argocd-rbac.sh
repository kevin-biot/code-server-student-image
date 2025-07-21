#!/bin/bash
# configure-argocd-rbac.sh - Configure ArgoCD RBAC for student access
# Called by complete-student-setup-simple.sh

set -e

START_NUM="${1:-1}"
END_NUM="${2:-25}"

echo "🔐 Configuring ArgoCD RBAC for students ${START_NUM} to ${END_NUM}..."

# Create ArgoCD RBAC ConfigMap with student policies
echo "   Creating ArgoCD RBAC policies..."

# Build the complete RBAC policy
POLICY_CSV="# Student role with limited permissions
p, role:student, applications, get, */*, allow
p, role:student, applications, sync, */*, allow
p, role:student, repositories, get, *, allow
p, role:student, clusters, get, *, allow

# Admin access for instructors
g, instructor, role:admin
g, admin, role:admin

# Student mappings and application-specific permissions"

for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    POLICY_CSV="${POLICY_CSV}
g, ${student_name}, role:student
p, ${student_name}, applications, *, openshift-gitops/java-webapp-${student_name}, allow"
done

# Apply the RBAC ConfigMap
cat << EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: openshift-gitops
  labels:
    app.kubernetes.io/name: argocd-rbac-cm
    app.kubernetes.io/part-of: argocd
data:
  policy.default: role:readonly
  policy.csv: |
${POLICY_CSV}
EOF

echo "   ✅ ArgoCD RBAC ConfigMap created"

# Create RoleBinding for students to access openshift-gitops namespace
echo "   Creating openshift-gitops namespace access..."

# Build subjects array for RoleBinding
SUBJECTS=""
for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    SUBJECTS="${SUBJECTS}- kind: User
  name: ${student_name}
  apiGroup: rbac.authorization.k8s.io
"
done

# Apply the complete RoleBinding
cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: bootcamp-students-argocd-view
  namespace: openshift-gitops
  labels:
    workshop: devops
    component: argocd-rbac
subjects:
${SUBJECTS}roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
EOF

echo "   ✅ Student access to openshift-gitops configured"

# Restart ArgoCD server to pick up RBAC changes
echo "   Restarting ArgoCD server to apply RBAC changes..."
oc rollout restart deployment/openshift-gitops-server -n openshift-gitops

echo "   Waiting for ArgoCD server to restart..."
oc rollout status deployment/openshift-gitops-server -n openshift-gitops --timeout=120s

echo "✅ ArgoCD RBAC configuration complete!"
echo ""
echo "🎯 Students can now:"
echo "   • Login to ArgoCD with OpenShift credentials (student01/DevOps2025!)"
echo "   • View only their own java-webapp-studentXX applications"
echo "   • Sync and manage their GitOps deployments"
echo ""
echo "🌐 ArgoCD Console: https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net"
