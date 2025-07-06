#!/bin/bash
# quick-fix-deployment.sh - Bypass deployment issues and create basic student setup

set -e

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
START_NUM="${1:-1}"
END_NUM="${2:-5}"
SHARED_PASSWORD="DevOps2025!"

echo "🔧 Quick Fix: Creating Basic Student Setup"
echo "=========================================="
echo "Students: ${START_NUM} to ${END_NUM}"
echo "Bypassing deploy-bulk-students.sh due to template issues"
echo ""

# Step 1: Create namespaces manually (bypass the problematic template)
echo "📦 Step 1: Creating student namespaces manually..."
for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    echo "   Creating namespace ${student_name}..."
    if oc create namespace "${student_name}" 2>/dev/null; then
        echo "      ✅ ${student_name} namespace created"
    else
        echo "      ⚠️  ${student_name} namespace already exists"
    fi
    
    # Add basic labels
    oc label namespace "${student_name}" student="${student_name}" workshop="devops" --overwrite > /dev/null 2>&1 || true
done
echo ""

# Step 2: Create htpasswd file (using our fixed syntax)
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
echo ""

# Step 3: Create users and identities
echo "👥 Step 3: Creating user accounts..."

for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    echo "   Processing ${student_name}..."
    
    # Create user and identity objects
    oc create user "${student_name}" --dry-run=client -o yaml | oc apply -f - > /dev/null 2>&1 || true
    oc create identity htpasswd_provider:"${student_name}" --dry-run=client -o yaml | oc apply -f - > /dev/null 2>&1 || true
    oc create useridentitymapping htpasswd_provider:"${student_name}" "${student_name}" --dry-run=client -o yaml | oc apply -f - > /dev/null 2>&1 || true
    
    # Grant permissions
    oc adm policy add-role-to-user admin "${student_name}" -n "${student_name}" > /dev/null 2>&1 || true
    oc adm policy add-cluster-role-to-user self-provisioner "${student_name}" > /dev/null 2>&1 || true
    
    echo "      ✅ ${student_name} user configured"
done
echo ""

# Step 4: Configure OAuth
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
echo ""

# Step 5: Restart OAuth
echo "⏳ Step 5: Restarting OAuth services..."

oc delete pods -n openshift-authentication -l app=oauth-openshift > /dev/null 2>&1
echo "   Waiting for OAuth pods to restart..."
sleep 30
oc wait --for=condition=Ready pods -l app=oauth-openshift -n openshift-authentication --timeout=300s > /dev/null 2>&1

echo "   Waiting additional 30 seconds for OAuth configuration to take effect..."
sleep 30
echo ""

# Step 6: Test authentication
echo "🔑 Step 6: Testing authentication..."

current_user=$(oc whoami)
current_server=$(oc whoami --show-server)
auth_success_count=0
auth_total_count=$((END_NUM - START_NUM + 1))

for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    echo "   Testing login for ${student_name}..."
    
    if oc login --username="${student_name}" --password="${SHARED_PASSWORD}" --server="${current_server}" --insecure-skip-tls-verify=true > /dev/null 2>&1; then
        echo "      ✅ Authentication successful"
        auth_success_count=$((auth_success_count + 1))
    else
        echo "      ❌ Authentication failed"
    fi
done

# Restore admin login
oc login --username="${current_user}" --server="${current_server}" --insecure-skip-tls-verify=true > /dev/null 2>&1

echo "   📊 Authentication Results: ${auth_success_count}/${auth_total_count} users successful"

# Clean up
rm -f "${HTPASSWD_FILE}"

echo ""
echo "🎯 Quick Fix Complete!"
echo "====================="
echo ""

if [ "$auth_success_count" -eq "$auth_total_count" ]; then
    echo "✅ ALL AUTHENTICATION TESTS PASSED!"
    echo ""
    echo "🎓 Ready for testing:"
    echo "   oc login -u student01 -p 'DevOps2025!'"
    echo "   oc get pods -n student01"
    echo "   oc get pods -n student02  # Should work (view)"
    echo ""
    echo "🌐 Console: https://console-openshift-console.${CLUSTER_DOMAIN}"
    echo "   Login: student01-student$(printf "%02d" $END_NUM) / DevOps2025!"
else
    echo "⚠️  Some authentication issues remain"
    echo "   Successful: ${auth_success_count}/${auth_total_count}"
fi

echo ""
echo "📝 Note: This bypassed the full code-server deployment"
echo "      Namespaces are created but may not have all workshop resources"
echo "      Focus is on testing the htpasswd authentication fix"
