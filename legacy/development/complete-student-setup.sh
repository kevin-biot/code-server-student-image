#!/bin/bash
# complete-student-setup.sh - One-script setup for production-ready student environment

set -e

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
START_NUM="${1:-1}"
END_NUM="${2:-25}"
STUDENT_PASSWORD="${3:-DevOps2025!}"

echo "🚀 Complete Student Environment Setup"
echo "====================================="
echo "Cluster Domain: ${CLUSTER_DOMAIN}"
echo "Students: ${START_NUM} to ${END_NUM}"
echo "Password: ${STUDENT_PASSWORD}"
echo ""

# Step 1: Deploy student environments
echo "📦 Step 1: Deploying student environments..."
./deploy-bulk-students.sh ${START_NUM} ${END_NUM} 5

# Step 2: Create user accounts with proper RBAC
echo "🔐 Step 2: Creating user accounts with production RBAC..."

# Create htpasswd file
HTPASSWD_FILE="/private/tmp/students.htpasswd"
rm -f "${HTPASSWD_FILE}"
touch "${HTPASSWD_FILE}"

for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    echo "🔑 Setting up ${student_name}..."
    
    # Add to htpasswd file
    htpasswd -Bb "${HTPASSWD_FILE}" "${student_name}" "${STUDENT_PASSWORD}"
    
    # Create user and identity objects with proper error handling
    oc create user "${student_name}" --dry-run=client -o yaml | oc apply -f - || true
    oc create identity htpasswd_provider:"${student_name}" --dry-run=client -o yaml | oc apply -f - || true
    oc create useridentitymapping htpasswd_provider:"${student_name}" "${student_name}" --dry-run=client -o yaml | oc apply -f - || true
    
    # Grant PRODUCTION-READY permissions (not cluster-admin!)
    # Admin access to their own namespace
    oc adm policy add-role-to-user admin "${student_name}" -n "${student_name}" || true
    
    # View access to shared namespaces for Day 2/3 exercises
    oc adm policy add-role-to-user view "${student_name}" -n devops || true
    oc adm policy add-role-to-user view "${student_name}" -n openshift-gitops || true
    oc adm policy add-role-to-user view "${student_name}" -n openshift-pipelines || true
    
    # Minimal cluster access for Console navigation (NO cluster-admin)
    # These roles allow Console access without dangerous permissions
    oc adm policy add-cluster-role-to-user self-provisioner "${student_name}" || true
    
    echo "  ✅ ${student_name} configured with production RBAC"
done

# Step 3: Configure OAuth with htpasswd provider
echo "🔧 Step 3: Configuring OAuth authentication..."

# Create/update htpasswd secret
oc delete secret htpass-secret -n openshift-config --ignore-not-found=true
oc create secret generic htpass-secret \
    --from-file=htpasswd="${HTPASSWD_FILE}" \
    -n openshift-config

# Update OAuth configuration
cat << EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpasswd_provider
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF

# Step 4: Enhanced project configurations
echo "🏷️  Step 4: Configuring project metadata and visibility..."

# Add proper labels and annotations to student namespaces
for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    # Update namespace with better metadata
    oc patch namespace "${student_name}" --patch '{
        "metadata": {
            "annotations": {
                "openshift.io/display-name": "Student '${i}' DevOps Workspace",
                "openshift.io/description": "Development environment for student'${i}' - DevOps Bootcamp",
                "openshift.io/requester": "'${student_name}'"
            },
            "labels": {
                "student": "'${student_name}'",
                "workshop": "devops-bootcamp",
                "environment": "training"
            }
        }
    }'
done

# Update devops namespace metadata
oc patch namespace devops --patch '{
    "metadata": {
        "annotations": {
            "openshift.io/display-name": "DevOps Shared Resources",
            "openshift.io/description": "Shared resources for DevOps bootcamp - builds, images, etc."
        }
    }
}'

# Step 5: Grant access to openshift-gitops for Day 3 ArgoCD exercises
echo "🔄 Step 5: Configuring ArgoCD access for Day 3..."

# Create a rolebinding in openshift-gitops for all students to view ArgoCD resources
cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: bootcamp-students-argocd-view
  namespace: openshift-gitops
subjects:
$(for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    echo "- kind: User"
    echo "  name: ${student_name}"
    echo "  apiGroup: rbac.authorization.k8s.io"
done)
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
EOF

# Step 6: Wait for OAuth configuration to take effect
echo "⏳ Step 6: Waiting for OAuth configuration..."
echo "   Deleting OAuth pods to force configuration reload..."
oc delete pods -n openshift-authentication -l app=oauth-openshift
echo "   Waiting for new OAuth pods to start..."
sleep 30
oc wait --for=condition=Ready pods -l app=oauth-openshift -n openshift-authentication --timeout=300s

# Step 7: Validation and summary
echo "✅ Step 7: Validation and summary..."

# Validate OAuth is working
echo "🔍 Validating OAuth configuration..."
if oc get oauth cluster -o jsonpath='{.spec.identityProviders[0].name}' | grep -q htpasswd_provider; then
    echo "  ✅ OAuth htpasswd provider configured"
else
    echo "  ❌ OAuth configuration issue"
fi

# Clean up temporary files
rm -f "${HTPASSWD_FILE}"

echo ""
echo "🎉 Complete Student Environment Setup Finished!"
echo "=============================================="
echo ""
echo "📋 Student Access Information:"
echo "==============================="
for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    echo "👤 ${student_name}:"
    echo "   Username: ${student_name}"
    echo "   Password: ${STUDENT_PASSWORD}"
    echo "   Console: https://console-openshift-console.${CLUSTER_DOMAIN}"
    echo "   Code-Server: https://${student_name}-code-server.${CLUSTER_DOMAIN}"
    echo ""
done

echo "🔐 Security Model:"
echo "=================="
echo "✅ Students have admin access to their own namespace"
echo "✅ Students have view access to shared resources (devops, openshift-gitops)"
echo "✅ Students can see cluster structure but cannot modify other namespaces"
echo "✅ Console access for visual learning (pipelines, ArgoCD)"
echo "✅ Code-Server access for development and CLI operations"
echo "❌ NO cluster-admin privileges (secure multi-tenant environment)"
echo ""
echo "🎓 Ready for bootcamp delivery!"
echo ""
echo "📝 Next Steps:"
echo "1. Test student login: Console + Code-Server"
echo "2. Verify ArgoCD access for Day 3 exercises"
echo "3. Begin internal staff testing (July 8-15)"
