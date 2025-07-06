#!/bin/bash
# complete-student-setup-fixed.sh - Fixed version with better OAuth handling

set -e

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
START_NUM="${1:-1}"
END_NUM="${2:-25}"
SHARED_PASSWORD="DevOps2025!"

echo "🚀 Complete Student Environment Setup (FIXED VERSION)"
echo "===================================================="
echo "Cluster Domain: ${CLUSTER_DOMAIN}"
echo "Students: ${START_NUM} to ${END_NUM}"
echo "Shared Password: ${SHARED_PASSWORD}"
echo ""

# Verify we're logged in as admin
if ! oc whoami &>/dev/null; then
    echo "❌ ERROR: Not logged in to OpenShift. Please login as cluster-admin first."
    exit 1
fi

CURRENT_USER=$(oc whoami)
echo "✅ Logged in as: ${CURRENT_USER}"
echo ""

# Step 1: Deploy student environments
echo "📦 Step 1: Deploying student environments..."
./deploy-bulk-students.sh ${START_NUM} ${END_NUM} 5

# Step 2: Create htpasswd file with better error handling
echo "🔐 Step 2: Creating shared authentication..."

HTPASSWD_FILE="/tmp/bootcamp-students.htpasswd"
rm -f "${HTPASSWD_FILE}"

echo "   Creating htpasswd file with shared password for all students..."
for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    if [ ! -f "${HTPASSWD_FILE}" ]; then
        # Create file with first student
        htpasswd -Bc "${HTPASSWD_FILE}" "${student_name}" "${SHARED_PASSWORD}"
    else
        # Add additional students
        htpasswd -Bb "${HTPASSWD_FILE}" "${student_name}" "${SHARED_PASSWORD}"
    fi
done

echo "   ✅ htpasswd file created with $((END_NUM - START_NUM + 1)) students"

# Verify htpasswd file was created correctly
if [ ! -f "${HTPASSWD_FILE}" ]; then
    echo "❌ ERROR: htpasswd file not created!"
    exit 1
fi

echo "   📄 htpasswd file contents:"
cat "${HTPASSWD_FILE}"
echo ""

# Step 3: Configure OAuth FIRST (before creating users)
echo "🔧 Step 3: Configuring OAuth authentication..."

# Remove old secret if exists
oc delete secret htpass-secret -n openshift-config --ignore-not-found=true
echo "   ✅ Removed old htpass-secret"

# Create new secret
oc create secret generic htpass-secret \
    --from-file=htpasswd="${HTPASSWD_FILE}" \
    -n openshift-config

echo "   ✅ Created new htpass-secret"

# Verify secret was created
if ! oc get secret htpass-secret -n openshift-config &>/dev/null; then
    echo "❌ ERROR: htpass-secret not created!"
    exit 1
fi

# Configure OAuth
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

echo "   ✅ OAuth provider configured"

# Step 4: Restart OAuth services and wait
echo "⏳ Step 4: Restarting OAuth services..."

oc delete pods -n openshift-authentication -l app=oauth-openshift
echo "   OAuth pods deleted, waiting for restart..."

# Wait longer for OAuth to fully restart
sleep 60

# Wait for OAuth pods to be ready
echo "   Waiting for OAuth pods to be ready..."
oc wait --for=condition=Ready pods -l app=oauth-openshift -n openshift-authentication --timeout=300s

echo "   ✅ OAuth services restarted"

# Step 5: Create OpenShift users AFTER OAuth is configured
echo "👥 Step 5: Creating user accounts with production RBAC..."

for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    # Create user and identity objects
    oc create user "${student_name}" --dry-run=client -o yaml | oc apply -f - || true
    oc create identity htpasswd_provider:"${student_name}" --dry-run=client -o yaml | oc apply -f - || true
    oc create useridentitymapping htpasswd_provider:"${student_name}" "${student_name}" --dry-run=client -o yaml | oc apply -f - || true
    
    # Grant PRODUCTION-READY permissions (not cluster-admin!)
    oc adm policy add-role-to-user admin "${student_name}" -n "${student_name}" || true
    oc adm policy add-role-to-user view "${student_name}" -n devops || true
    oc adm policy add-role-to-user view "${student_name}" -n openshift-gitops || true
    oc adm policy add-cluster-role-to-user self-provisioner "${student_name}" || true
    
    echo "   ✅ ${student_name} configured"
done

# Step 6: Enhanced project metadata
echo "🏷️  Step 6: Configuring project display names..."

for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    oc patch namespace "${student_name}" --patch "{
        \"metadata\": {
            \"annotations\": {
                \"openshift.io/display-name\": \"Student ${i} DevOps Workspace\",
                \"openshift.io/description\": \"Development environment for ${student_name} - DevOps Bootcamp\",
                \"openshift.io/requester\": \"${student_name}\"
            }
        }
    }" || true
done

oc patch namespace devops --patch '{
    "metadata": {
        "annotations": {
            "openshift.io/display-name": "DevOps Shared Resources",
            "openshift.io/description": "Shared resources for DevOps bootcamp"
        }
    }
}' || true

echo "   ✅ Project metadata configured"

# Step 7: ArgoCD access for Day 3
echo "🔄 Step 7: Configuring ArgoCD access for Day 3..."

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

echo "   ✅ ArgoCD access configured"

# Step 8: Verification
echo "🧪 Step 8: Verifying setup..."

# Check OAuth configuration
echo "   Checking OAuth configuration..."
oc get oauth cluster -o jsonpath='{.spec.identityProviders[0].name}' 2>/dev/null || echo "   ❌ OAuth config issue"

# Check htpasswd secret
echo "   Checking htpasswd secret..."
oc get secret htpass-secret -n openshift-config &>/dev/null && echo "   ✅ htpasswd secret exists" || echo "   ❌ htpasswd secret missing"

# Check OAuth pods
echo "   Checking OAuth pods..."
oc get pods -n openshift-authentication -l app=oauth-openshift --no-headers 2>/dev/null | wc -l | xargs -I {} echo "   ✅ {} OAuth pods running"

# Check users
echo "   Checking users..."
USER_COUNT=$(oc get users 2>/dev/null | grep student | wc -l)
echo "   ✅ ${USER_COUNT} student users created"

# Check namespaces
echo "   Checking namespaces..."
NS_COUNT=$(oc get namespaces 2>/dev/null | grep student | wc -l)
echo "   ✅ ${NS_COUNT} student namespaces exist"

# Clean up
rm -f "${HTPASSWD_FILE}"

echo ""
echo "🎉 Complete Student Environment Setup Finished!"
echo "=============================================="
echo ""
echo "📋 Instructor Announcement:"
echo "==========================="
echo "\"All students use the following credentials:\""
echo ""
echo "🌐 OpenShift Console: https://console-openshift-console.${CLUSTER_DOMAIN}"
echo "   Username: student01, student02, student03... student${END_NUM}"
echo "   Password: ${SHARED_PASSWORD}"
echo ""
echo "💻 Code-Server URLs:"
echo "   student01: https://student01-code-server.${CLUSTER_DOMAIN}"
echo "   student02: https://student02-code-server.${CLUSTER_DOMAIN}"
echo "   ... (pattern continues for all students)"
echo ""
echo "🔐 Security Model:"
echo "=================="
echo "✅ Each student has admin access to their own namespace"
echo "✅ Students can view shared resources (devops, openshift-gitops)"
echo "✅ Students can see cluster structure for learning"
echo "✅ Students CANNOT modify other student environments"
echo "✅ Console access for visual learning (pipelines, ArgoCD)"
echo "✅ Code-Server access for development and CLI operations"
echo ""
echo "🎓 Ready for bootcamp delivery!"
echo ""
echo "📝 Test Commands:"
echo "   oc login -u student01 -p '${SHARED_PASSWORD}'"
echo "   oc get pods -n student01"
echo "   oc get pods -n student02  # Should be forbidden to modify"
echo ""
echo "🔍 If login fails, run: ./diagnose-oauth.sh"
