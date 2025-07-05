#!/bin/bash
# complete-student-setup-simple.sh - Streamlined production setup with shared password

set -e

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
START_NUM="${1:-1}"
END_NUM="${2:-25}"
SHARED_PASSWORD="DevOps2025!"

echo "🚀 Complete Student Environment Setup (Streamlined)"
echo "=================================================="
echo "Cluster Domain: ${CLUSTER_DOMAIN}"
echo "Students: ${START_NUM} to ${END_NUM}"
echo "Shared Password: ${SHARED_PASSWORD} (instructor announces to class)"
echo ""

# Step 1: Deploy student environments
echo "📦 Step 1: Deploying student environments..."
./deploy-bulk-students.sh ${START_NUM} ${END_NUM} 5

# Step 2: Create single htpasswd file for all students
echo "🔐 Step 2: Creating shared authentication..."

HTPASSWD_FILE="/private/tmp/bootcamp-students.htpasswd"
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

echo "   ✅ htpasswd file created with ${END_NUM} students"

# Step 3: Create OpenShift users and configure RBAC
echo "👥 Step 3: Creating user accounts with production RBAC..."

for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    # Create user and identity objects
    oc create user "${student_name}" --dry-run=client -o yaml | oc apply -f - > /dev/null 2>&1 || true
    oc create identity htpasswd_provider:"${student_name}" --dry-run=client -o yaml | oc apply -f - > /dev/null 2>&1 || true
    oc create useridentitymapping htpasswd_provider:"${student_name}" "${student_name}" --dry-run=client -o yaml | oc apply -f - > /dev/null 2>&1 || true
    
    # Grant PRODUCTION-READY permissions (not cluster-admin!)
    oc adm policy add-role-to-user admin "${student_name}" -n "${student_name}" > /dev/null 2>&1 || true
    oc adm policy add-role-to-user view "${student_name}" -n devops > /dev/null 2>&1 || true
    oc adm policy add-role-to-user view "${student_name}" -n openshift-gitops > /dev/null 2>&1 || true
    oc adm policy add-cluster-role-to-user self-provisioner "${student_name}" > /dev/null 2>&1 || true
    
    echo "   ✅ ${student_name} configured"
done

# Step 4: Configure OAuth with htpasswd provider
echo "🔧 Step 4: Configuring OAuth authentication..."

oc delete secret htpass-secret -n openshift-config --ignore-not-found=true > /dev/null 2>&1
oc create secret generic htpass-secret \
    --from-file=htpasswd="${HTPASSWD_FILE}" \
    -n openshift-config > /dev/null

cat << EOF | oc apply -f - > /dev/null
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

# Step 5: Enhanced project metadata
echo "🏷️  Step 5: Configuring project display names..."

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
    }" > /dev/null 2>&1 || true
done

oc patch namespace devops --patch '{
    "metadata": {
        "annotations": {
            "openshift.io/display-name": "DevOps Shared Resources",
            "openshift.io/description": "Shared resources for DevOps bootcamp"
        }
    }
}' > /dev/null 2>&1 || true

echo "   ✅ Project metadata configured"

# Step 6: ArgoCD access for Day 3
echo "🔄 Step 6: Configuring ArgoCD access for Day 3..."

cat << EOF | oc apply -f - > /dev/null
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

# Step 7: OAuth restart and validation
echo "⏳ Step 7: Restarting OAuth services..."

oc delete pods -n openshift-authentication -l app=oauth-openshift > /dev/null 2>&1
echo "   Waiting for OAuth pods to restart..."
sleep 30
oc wait --for=condition=Ready pods -l app=oauth-openshift -n openshift-authentication --timeout=300s > /dev/null 2>&1

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
