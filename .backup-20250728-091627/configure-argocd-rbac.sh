#!/bin/bash
# configure-argocd-rbac.sh - Configure ArgoCD RBAC for student access
# UPDATED: Uses defaultPolicy approach (VALIDATED WORKING)

set -e

START_NUM="${1:-1}"
END_NUM="${2:-25}"

echo "🔐 Configuring ArgoCD RBAC for students ${START_NUM} to ${END_NUM}..."
echo "📝 Method: defaultPolicy=role:student (all authenticated users get student access)"
echo "🔍 VALIDATED: This approach works and is future-proof"
echo ""

# Apply the CLEAN, WORKING RBAC configuration
echo "   Applying ArgoCD RBAC via Custom Resource..."

oc patch argocd openshift-gitops -n openshift-gitops --type merge --patch '{
  "spec": {
    "rbac": {
      "defaultPolicy": "role:student",
      "policy": "# Admin access\ng, system:cluster-admins, role:admin\ng, cluster-admins, role:admin\ng, instructor, role:admin\ng, admin, role:admin\n\n# Student role permissions (granted to all authenticated users)\np, role:student, applications, *, */*, allow\np, role:student, repositories, get, *, allow\np, role:student, clusters, get, *, allow",
      "scopes": "[groups]"
    }
  }
}'

echo "   ✅ ArgoCD RBAC configuration applied"
echo "   📝 All authenticated users now have student role by default"

# Wait for operator to apply changes
echo "   ⏳ Waiting for ArgoCD operator to apply changes..."
sleep 15

echo "✅ ArgoCD RBAC configuration complete!"
echo ""
echo "🎯 Result:"
echo "   • ALL authenticated students can login to ArgoCD console"
echo "   • ALL students can view and sync applications"
echo "   • Admins retain admin access via group mapping"
echo "   • NO individual user mapping required"
echo ""
echo "🌐 ArgoCD Console: https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net"
echo ""
echo "🔧 Method: defaultPolicy approach (VALIDATED WORKING)"
echo "   ✅ Simple and reliable for future deployments"
echo "   ✅ No JWT subject mapping needed"
echo "   ✅ All students work automatically"
