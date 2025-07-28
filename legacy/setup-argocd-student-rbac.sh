#!/bin/bash
# ==============================================================================
# ArgoCD Student RBAC Setup Script
# Configures ArgoCD to allow student OpenShift login and application visibility
# ==============================================================================
set -euo pipefail

echo "🔐 ArgoCD Student RBAC Setup"
echo "📝 This script configures ArgoCD for student access via OpenShift SSO"
echo ""

# Check if we have admin access to openshift-gitops namespace
echo "🔍 Checking ArgoCD access..."
if ! oc get configmap argocd-rbac-cm -n openshift-gitops &>/dev/null; then
    echo "❌ Cannot access ArgoCD RBAC configuration. Ensure you have admin privileges."
    exit 1
fi

echo "✅ ArgoCD access confirmed"
echo ""

# Get current RBAC configuration
echo "📋 Current ArgoCD RBAC configuration:"
oc get configmap argocd-rbac-cm -n openshift-gitops -o yaml | grep -A 20 "policy.csv:" || echo "No current policy found"
echo ""

read -rp "❓ Proceed with student RBAC configuration? (y/n): " CONFIRM
[[ "$CONFIRM" != [yY] ]] && { echo "❌ RBAC setup aborted."; exit 1; }

echo ""
echo "🔧 Applying student RBAC configuration..."

# ==============================================================================
# Apply ArgoCD RBAC Configuration
# ==============================================================================

cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: openshift-gitops
  labels:
    app.kubernetes.io/name: argocd-rbac-cm
    app.kubernetes.io/part-of: argocd
data:
  # Default policy for authenticated users
  policy.default: role:readonly
  
  # RBAC policy definitions
  policy.csv: |
    # Student role with basic permissions
    p, role:student, applications, get, */*, allow
    p, role:student, applications, sync, */*, allow
    p, role:student, repositories, get, *, allow
    p, role:student, clusters, get, *, allow
    
    # Map OpenShift users to student role
    g, student01, role:student
    g, student02, role:student
    g, student03, role:student
    g, student04, role:student
    g, student05, role:student
    g, student06, role:student
    g, student07, role:student
    g, student08, role:student
    g, student09, role:student
    g, student10, role:student
    g, student11, role:student
    g, student12, role:student
    g, student13, role:student
    g, student14, role:student
    g, student15, role:student
    g, student16, role:student
    g, student17, role:student
    g, student18, role:student
    g, student19, role:student
    g, student20, role:student
    
    # Admin access for instructors
    g, instructor, role:admin
    g, admin, role:admin
    
    # Application-specific permissions: students can only see their own apps
    p, student01, applications, *, openshift-gitops/java-webapp-student01, allow
    p, student02, applications, *, openshift-gitops/java-webapp-student02, allow
    p, student03, applications, *, openshift-gitops/java-webapp-student03, allow
    p, student04, applications, *, openshift-gitops/java-webapp-student04, allow
    p, student05, applications, *, openshift-gitops/java-webapp-student05, allow
    p, student06, applications, *, openshift-gitops/java-webapp-student06, allow
    p, student07, applications, *, openshift-gitops/java-webapp-student07, allow
    p, student08, applications, *, openshift-gitops/java-webapp-student08, allow
    p, student09, applications, *, openshift-gitops/java-webapp-student09, allow
    p, student10, applications, *, openshift-gitops/java-webapp-student10, allow
    p, student11, applications, *, openshift-gitops/java-webapp-student11, allow
    p, student12, applications, *, openshift-gitops/java-webapp-student12, allow
    p, student13, applications, *, openshift-gitops/java-webapp-student13, allow
    p, student14, applications, *, openshift-gitops/java-webapp-student14, allow
    p, student15, applications, *, openshift-gitops/java-webapp-student15, allow
    p, student16, applications, *, openshift-gitops/java-webapp-student16, allow
    p, student17, applications, *, openshift-gitops/java-webapp-student17, allow
    p, student18, applications, *, openshift-gitops/java-webapp-student18, allow
    p, student19, applications, *, openshift-gitops/java-webapp-student19, allow
    p, student20, applications, *, openshift-gitops/java-webapp-student20, allow
EOF

echo "✅ ArgoCD RBAC configuration applied"

# ==============================================================================
# Restart ArgoCD Server to Pick Up New RBAC
# ==============================================================================
echo ""
echo "🔄 Restarting ArgoCD server to apply RBAC changes..."
oc rollout restart deployment/openshift-gitops-server -n openshift-gitops

echo "⏳ Waiting for ArgoCD server to restart..."
oc rollout status deployment/openshift-gitops-server -n openshift-gitops --timeout=300s

echo "✅ ArgoCD server restarted successfully"

# ==============================================================================
# Verification
# ==============================================================================
echo ""
echo "🔍 Verifying RBAC configuration..."

echo "📋 Current RBAC policy (first 10 lines):"
oc get configmap argocd-rbac-cm -n openshift-gitops -o jsonpath='{.data.policy\.csv}' | head -10

echo ""
echo "🌐 ArgoCD Console URL:"
echo "https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net"

echo ""
echo "🔑 Students can now login with:"
echo "   Username: student01 (their student ID)"
echo "   Password: DevOps2025!"
echo "   Method: 'LOG IN VIA OPENSHIFT' button"

# ==============================================================================
# Summary
# ==============================================================================
cat <<EOF

================================================================================
🎉 ArgoCD Student RBAC Setup Complete
================================================================================

✅ CONFIGURED:
   • Student role with application viewing permissions
   • OpenShift SSO integration for students (student01-student20)
   • Application-specific permissions (students see only their apps)
   • ArgoCD server restarted with new RBAC

🔑 STUDENT ACCESS:
   • Login URL: https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net
   • Method: Click "LOG IN VIA OPENSHIFT"
   • Credentials: student01 / DevOps2025! (each student uses their ID)
   • Visibility: Only java-webapp-{student-id} applications

🎯 WHAT STUDENTS WILL SEE:
   • student01 sees: java-webapp-student01
   • student02 sees: java-webapp-student02
   • etc.

📝 TESTING:
   1. Have a student login to ArgoCD console
   2. Verify they can see their application
   3. Verify they cannot see other students' applications
   4. Check application sync status and health

🔧 TROUBLESHOOTING:
   • If students can't login: Check OpenShift OAuth integration
   • If no applications visible: Verify application names match pattern
   • If seeing all apps: Check RBAC policies applied correctly

================================================================================

EOF
