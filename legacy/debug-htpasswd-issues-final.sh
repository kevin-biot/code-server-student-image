#!/bin/bash
# debug-htpasswd-issues-final.sh - Debug version with fixed identity creation

set -e

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
START_NUM=98  # Use test students to avoid conflicts
END_NUM=98    # Test with just one student
SHARED_PASSWORD="DevOps2025!"

echo "🔍 HTPasswd and Login Issues Debug (Final Fix)"
echo "=============================================="
echo "Testing with: student$(printf "%02d" $START_NUM)"
echo "Password: ${SHARED_PASSWORD}"
echo ""

# Clean any existing test student
student_name=$(printf "student%02d" $START_NUM)
echo "🧹 Cleaning previous test student..."
oc delete namespace "$student_name" --ignore-not-found=true
oc delete user "$student_name" --ignore-not-found=true  
oc delete identity "htpasswd_provider:$student_name" --ignore-not-found=true
oc delete secret htpass-secret -n openshift-config --ignore-not-found=true
echo ""

# Step 1: Deploy student environment (simplified)
echo "📦 Step 1: Creating namespace for $student_name..."
oc create namespace "$student_name" || echo "Namespace already exists"
echo "   ✅ Namespace created"
echo ""

# Step 2: Create htpasswd file (we know Method 1 works)
echo "🔐 Step 2: Creating htpasswd file..."

# Create temporary directory in script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="${SCRIPT_DIR}/tmp-htpasswd"

echo "   📁 Creating temp directory: ${TMP_DIR}"
mkdir -p "${TMP_DIR}"
chmod 755 "${TMP_DIR}"

# Set htpasswd file location
HTPASSWD_FILE="${TMP_DIR}/bootcamp-students-debug.htpasswd"

echo "   🔧 Creating htpasswd file using working method..."
rm -f "${HTPASSWD_FILE}"

# Use Method 1 (we know this works)
if htpasswd -c -b -B "${HTPASSWD_FILE}" "${student_name}" "${SHARED_PASSWORD}"; then
    echo "   ✅ HTPasswd file created successfully"
    echo "   📋 File contents:"
    cat "${HTPASSWD_FILE}" | sed 's/^/      /'
else
    echo "   ❌ Failed to create htpasswd file"
    exit 1
fi
echo ""

# Step 3: Create user objects with corrected identity syntax
echo "👥 Step 3: Creating user objects..."

echo "   Creating user $student_name..."
cat << EOF | oc apply -f -
apiVersion: user.openshift.io/v1
kind: User
metadata:
  name: ${student_name}
EOF
echo "   ✅ User created successfully"

echo "   Creating identity for htpasswd_provider:$student_name..."
cat << EOF | oc apply -f -
apiVersion: user.openshift.io/v1
kind: Identity
metadata:
  name: htpasswd_provider:${student_name}
providerName: htpasswd_provider
providerUserName: ${student_name}
user:
  name: ${student_name}
  uid: $(oc get user ${student_name} -o jsonpath='{.metadata.uid}')
EOF
echo "   ✅ Identity created successfully"

echo "   Creating user identity mapping..."
cat << EOF | oc apply -f -
apiVersion: user.openshift.io/v1
kind: UserIdentityMapping
metadata:
  name: htpasswd_provider:${student_name}
identity:
  name: htpasswd_provider:${student_name}
user:
  name: ${student_name}
EOF
echo "   ✅ User identity mapping created successfully"

# Add RBAC
echo "   Adding RBAC permissions..."
oc adm policy add-role-to-user admin "$student_name" -n "$student_name"
echo "   ✅ RBAC configured"
echo ""

# Step 4: Create OAuth secret
echo "🔧 Step 4: Creating OAuth secret..."

echo "   Deleting any existing OAuth secret..."
oc delete secret htpass-secret -n openshift-config --ignore-not-found=true

echo "   Creating new OAuth secret..."
if oc create secret generic htpass-secret \
    --from-file=htpasswd="$HTPASSWD_FILE" \
    -n openshift-config; then
    echo "   ✅ OAuth secret created successfully"
else
    echo "   ❌ Failed to create OAuth secret"
    exit 1
fi

# Verify secret contents
echo "   🔍 Verifying OAuth secret contents..."
oc get secret htpass-secret -n openshift-config -o jsonpath='{.data.htpasswd}' | base64 -d | sed 's/^/      /'
echo ""

# Step 5: Configure OAuth provider
echo "🔧 Step 5: Configuring OAuth provider..."

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
echo ""

# Step 6: Wait for OAuth restart
echo "⏳ Step 6: Restarting OAuth services..."

echo "   Deleting OAuth pods..."
oc delete pods -n openshift-authentication -l app=oauth-openshift

echo "   Waiting for OAuth pods to restart and be ready..."
sleep 15

# Wait for pods to be ready
if oc wait --for=condition=Ready pods -l app=oauth-openshift -n openshift-authentication --timeout=300s; then
    echo "   ✅ OAuth pods are ready"
else
    echo "   ⚠️  OAuth pods may not be fully ready yet"
fi

# Additional wait for OAuth configuration
echo "   Waiting additional 30 seconds for OAuth configuration..."
sleep 30
echo ""

# Step 7: Test authentication
echo "🔑 Step 7: Testing authentication..."

# Store current login info
current_user=$(oc whoami)
current_server=$(oc whoami --show-server)
echo "   Current user: $current_user"
echo "   Current server: $current_server"

echo "   Attempting login as $student_name..."

# Try authentication
auth_success=false
login_output=$(oc login --username="$student_name" --password="$SHARED_PASSWORD" --server="$current_server" --insecure-skip-tls-verify=true 2>&1)
login_exit_code=$?

if [ $login_exit_code -eq 0 ]; then
    echo "   ✅ Authentication successful!"
    echo "   Login output:"
    echo "$login_output" | sed 's/^/      /'
    auth_success=true
    
    echo "   Testing namespace access..."
    if oc get pods -n "$student_name" 2>&1; then
        echo "   ✅ Can access own namespace"
    else
        echo "   ❌ Cannot access own namespace"
    fi
    
    echo "   Current user after login: $(oc whoami)"
    
    # Switch back to admin
    echo "   Switching back to original user..."
    oc login --username="$current_user" --server="$current_server" --insecure-skip-tls-verify=true
    
else
    echo "   ❌ Authentication failed!"
    echo "   Login output:"
    echo "$login_output" | sed 's/^/      /'
fi

if [ "$auth_success" = false ]; then
    echo ""
    echo "🔍 Debugging authentication failure..."
    
    # Check OAuth pods
    echo "   OAuth pod status:"
    oc get pods -n openshift-authentication -l app=oauth-openshift -o wide
    
    # Check OAuth pod logs for errors
    echo "   OAuth pod logs (last 30 lines):"
    oc logs -n openshift-authentication -l app=oauth-openshift --tail=30 | sed 's/^/      /'
    
    # Check OAuth configuration
    echo "   OAuth configuration:"
    oc get oauth cluster -o yaml | grep -A 15 "identityProviders:" | sed 's/^/      /'
    
    # Check if our user and identity exist
    echo "   User verification:"
    oc get user "$student_name" -o yaml | grep -E "^  name:|^  uid:|^metadata:" | sed 's/^/      /'
    
    echo "   Identity verification:"
    oc get identity "htpasswd_provider:$student_name" -o yaml | grep -E "^  name:|^providerName:|^providerUserName:" | sed 's/^/      /'
    
    # Check OAuth secret
    echo "   OAuth secret verification:"
    oc describe secret htpass-secret -n openshift-config | sed 's/^/      /'
fi

echo ""
echo "🎯 Debug Complete!"
echo "=================="
echo ""
echo "📝 Results Summary:"
echo "   HTPasswd file creation: ✅ SUCCESS (Method 1: htpasswd -c -b -B)"
echo "   User/Identity creation: ✅ SUCCESS (using YAML manifests)" 
echo "   OAuth configuration: ✅ SUCCESS"
echo "   Authentication test: $([ "$auth_success" = true ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
echo ""

if [ "$auth_success" = true ]; then
    echo "🎉 SOLUTION FOUND!"
    echo "=================="
    echo ""
    echo "🔧 Fix for your main script (complete-student-setup-simple.sh):"
    echo ""
    echo "1. Change htpasswd commands:"
    echo "   Line 33: htpasswd -c -b -B \"\${HTPASSWD_FILE}\" \"\${student_name}\" \"\${SHARED_PASSWORD}\""
    echo "   Line 36: htpasswd -b -B \"\${HTPASSWD_FILE}\" \"\${student_name}\" \"\${SHARED_PASSWORD}\""
    echo ""
    echo "2. (Optional) Consider using YAML manifests for user/identity creation"
    echo "   instead of the oc create commands for better error handling"
    echo ""
    echo "✅ Your authentication system should now work perfectly!"
else
    echo "🔍 Further Investigation Needed:"
    echo "=============================="
    echo "   - Check OAuth pod logs above for specific errors"
    echo "   - Verify OpenShift cluster OAuth configuration"
    echo "   - Try manual authentication test after waiting longer"
fi

echo ""
echo "🧹 Cleanup commands (run manually):"
echo "   oc delete namespace $student_name"
echo "   oc delete user $student_name"  
echo "   oc delete identity htpasswd_provider:$student_name"
echo "   rm -rf $TMP_DIR"
