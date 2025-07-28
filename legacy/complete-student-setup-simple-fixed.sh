#!/bin/bash
# complete-student-setup-simple-fixed.sh - Minimal fix for htpasswd issues

set -e

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
START_NUM="${1:-98}"  # Default to test students
END_NUM="${2:-99}"    # Default to test students
SHARED_PASSWORD="DevOps2025!"

echo "🚀 Complete Student Environment Setup (Fixed - Minimal)"
echo "======================================================="
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
        # Create file with first student - FIXED SYNTAX
        echo "      Creating htpasswd file with ${student_name}..."
        htpasswd -c -b -B "${HTPASSWD_FILE}" "${student_name}" "${SHARED_PASSWORD}"
    else
        # Add additional students - FIXED SYNTAX
        echo "      Adding ${student_name} to htpasswd file..."
        htpasswd -b -B "${HTPASSWD_FILE}" "${student_name}" "${SHARED_PASSWORD}"
    fi
done

echo "   ✅ htpasswd file created with $((END_NUM - START_NUM + 1)) students"

# Verify htpasswd file
echo "   📋 HTPasswd file contents:"
cat "${HTPASSWD_FILE}" | sed 's/^/      /'

# Step 3: Create OpenShift users and configure RBAC
echo "👥 Step 3: Creating user accounts with production RBAC..."

for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    echo "   Processing ${student_name}..."
    
    # Create user and identity objects - REMOVED || true TO SEE ERRORS
    echo "      Creating user..."
    oc create user "${student_name}" --dry-run=client -o yaml | oc apply -f - > /dev/null 2>&1
    
    echo "      Creating identity..."
    oc create identity htpasswd_provider:"${student_name}" --dry-run=client -o yaml | oc apply -f - > /dev/null 2>&1
    
    echo "      Creating user identity mapping..."
    oc create useridentitymapping htpasswd_provider:"${student_name}" "${student_name}" --dry-run=client -o yaml | oc apply -f - > /dev/null 2>&1
    
    # Grant PRODUCTION-READY permissions (not cluster-admin!)
    echo "      Adding RBAC permissions..."
    oc adm policy add-role-to-user admin "${student_name}" -n "${student_name}" > /dev/null 2>&1
    oc adm policy add-role-to-user view "${student_name}" -n devops > /dev/null 2>&1
    oc adm policy add-role-to-user view "${student_name}" -n openshift-gitops > /dev/null 2>&1
    oc adm policy add-cluster-role-to-user self-provisioner "${student_name}" > /dev/null 2>&1
    
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
    }" > /dev/null 2>&1
done

oc patch namespace devops --patch '{
    "metadata": {
        "annotations": {
            "openshift.io/display-name": "DevOps Shared Resources",
            "openshift.io/description": "Shared resources for DevOps bootcamp"
        }
    }
}' > /dev/null 2>&1 || echo "   ⚠️  Could not update devops namespace (may not exist yet)"

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

echo "   Waiting additional 30 seconds for OAuth configuration to take effect..."
sleep 30

# NEW: Step 8: Authentication validation for each user
echo "🔑 Step 8: Validating authentication for each user..."

# Store current login info
current_user=$(oc whoami)
current_server=$(oc whoami --show-server)
echo "   Current admin user: ${current_user}"

auth_success_count=0
auth_total_count=$((END_NUM - START_NUM + 1))

for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    echo "   🧪 Testing login for ${student_name}..."
    
    # Test authentication
    if oc login --username="${student_name}" --password="${SHARED_PASSWORD}" --server="${current_server}" --insecure-skip-tls-verify=true > /dev/null 2>&1; then
        echo "      ✅ Authentication successful"
        
        # Test namespace access
        if oc get pods -n "${student_name}" > /dev/null 2>&1; then
            echo "      ✅ Can access own namespace"
            auth_success_count=$((auth_success_count + 1))
        else
            echo "      ❌ Cannot access own namespace"
        fi
    else
        echo "      ❌ Authentication failed"
    fi
done

# Restore admin login
echo "   🔄 Restoring admin login..."
oc login --username="${current_user}" --server="${current_server}" --insecure-skip-tls-verify=true > /dev/null 2>&1

echo "   📊 Authentication Results: ${auth_success_count}/${auth_total_count} users successful"

if [ "$auth_success_count" -eq "$auth_total_count" ]; then
    echo "   ✅ All users authenticated successfully!"
else
    echo "   ⚠️  Some users failed authentication - see details above"
fi

# Clean up htpasswd file
rm -f "${HTPASSWD_FILE}"

echo ""
echo "🎉 Complete Student Environment Setup Finished!"
echo "=============================================="
echo ""
echo "📊 Final Status:"
echo "   Students processed: ${START_NUM} to ${END_NUM}"
echo "   Authentication success rate: ${auth_success_count}/${auth_total_count}"
echo ""

if [ "$auth_success_count" -eq "$auth_total_count" ]; then
    echo "✅ ALL SYSTEMS GO! Ready for bootcamp delivery!"
    echo ""
    echo "📋 Instructor Announcement:"
    echo "==========================="
    echo "\"All students use the following credentials:\""
    echo ""
    echo "🌐 OpenShift Console: https://console-openshift-console.${CLUSTER_DOMAIN}"
    echo "   Username: student$(printf "%02d" $START_NUM), student$(printf "%02d" $((START_NUM + 1))), student$(printf "%02d" $((START_NUM + 2)))... student$(printf "%02d" $END_NUM)"
    echo "   Password: ${SHARED_PASSWORD}"
    echo ""
    echo "💻 Code-Server URLs:"
    for i in $(seq $START_NUM $((START_NUM + 2))); do
        student_name=$(printf "student%02d" $i)
        echo "   ${student_name}: https://${student_name}-code-server.${CLUSTER_DOMAIN}"
    done
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
else
    echo "⚠️  SETUP INCOMPLETE - Some authentication issues remain"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "   1. Check OAuth pod logs: oc logs -n openshift-authentication -l app=oauth-openshift"
    echo "   2. Verify htpasswd secret: oc get secret htpass-secret -n openshift-config -o yaml"
    echo "   3. Re-run with same parameters to retry failed users"
fi

echo ""
echo "📝 Test Commands:"
echo "   oc login -u student$(printf "%02d" $START_NUM) -p '${SHARED_PASSWORD}'"
echo "   oc get pods -n student$(printf "%02d" $START_NUM)"
echo "   oc get pods -n student$(printf "%02d" $((START_NUM + 1)))  # Should be forbidden to modify"
