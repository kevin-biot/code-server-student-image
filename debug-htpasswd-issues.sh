#!/bin/bash
# debug-htpasswd-issues.sh - Debug version to identify htpasswd and login issues

set -e

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
START_NUM=98  # Use test students to avoid conflicts
END_NUM=98    # Test with just one student
SHARED_PASSWORD="DevOps2025!"

echo "🔍 HTPasswd and Login Issues Debug"
echo "=================================="
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

# Step 2: Create temporary directory and htpasswd file
echo "🔐 Step 2: Creating temporary directory and htpasswd file..."

# Create temporary directory in script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="${SCRIPT_DIR}/tmp-htpasswd"

echo "   📁 Script directory: ${SCRIPT_DIR}"
echo "   📁 Creating temp directory: ${TMP_DIR}"

# Create the temporary directory
mkdir -p "${TMP_DIR}"
chmod 755 "${TMP_DIR}"

echo "   ✅ Temporary directory created"
echo "   📊 Directory permissions: $(ls -ld "${TMP_DIR}")"

# Set htpasswd file location
HTPASSWD_FILE="${TMP_DIR}/bootcamp-students-debug.htpasswd"

# Clean any existing file
rm -f "${HTPASSWD_FILE}"

echo "   🧪 Creating htpasswd file at: ${HTPASSWD_FILE}"

# Try to create htpasswd file
if htpasswd -Bc "${HTPASSWD_FILE}" "$student_name" "$SHARED_PASSWORD" 2>&1; then
    echo "   ✅ HTPasswd file created successfully"
    
    # Check file contents
    echo "   📋 File contents:"
    cat "${HTPASSWD_FILE}" | sed 's/^/      /'
    
    # Check file permissions
    echo "   📊 File permissions: $(ls -la "${HTPASSWD_FILE}")"
    
    # Test if we can read it back
    if [ -r "${HTPASSWD_FILE}" ]; then
        echo "   ✅ File is readable"
    else
        echo "   ❌ File is not readable"
        exit 1
    fi
else
    echo "   ❌ Failed to create htpasswd file"
    exit 1
fi

echo "✅ Using htpasswd file: $HTPASSWD_FILE"
echo ""

# Step 3: Create user objects with verbose output
echo "👥 Step 3: Creating user objects..."

echo "   Creating user $student_name..."
if oc create user "$student_name" --dry-run=client -o yaml | oc apply -f -; then
    echo "   ✅ User created successfully"
else
    echo "   ❌ Failed to create user"
    exit 1
fi

echo "   Creating identity htpasswd_provider:$student_name..."
if oc create identity "htpasswd_provider:$student_name" --dry-run=client -o yaml | oc apply -f -; then
    echo "   ✅ Identity created successfully"
else
    echo "   ❌ Failed to create identity"
    exit 1
fi

echo "   Creating user identity mapping..."
if oc create useridentitymapping "htpasswd_provider:$student_name" "$student_name" --dry-run=client -o yaml | oc apply -f -; then
    echo "   ✅ User identity mapping created successfully"
else
    echo "   ❌ Failed to create user identity mapping"
    exit 1
fi

# Add RBAC
echo "   Adding RBAC permissions..."
oc adm policy add-role-to-user admin "$student_name" -n "$student_name"
echo "   ✅ RBAC configured"
echo ""

# Step 4: Create OAuth secret with verbose output
echo "🔧 Step 4: Creating OAuth secret..."

echo "   Deleting any existing OAuth secret..."
oc delete secret htpass-secret -n openshift-config --ignore-not-found=true

echo "   Creating new OAuth secret..."
echo "   Using htpasswd file: $HTPASSWD_FILE"
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
oc get secret htpass-secret -n openshift-config -o jsonpath='{.data.htpasswd}' | base64 -d
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

# Step 6: Wait for OAuth restart with monitoring
echo "⏳ Step 6: Restarting and monitoring OAuth services..."

echo "   Deleting OAuth pods..."
oc delete pods -n openshift-authentication -l app=oauth-openshift

echo "   Waiting for OAuth pods to restart..."
sleep 10

echo "   Monitoring OAuth pod status..."
for i in {1..30}; do
    pod_status=$(oc get pods -n openshift-authentication -l app=oauth-openshift --no-headers 2>/dev/null | awk '{print $3}' | head -1)
    echo "   Attempt $i/30: OAuth pod status = $pod_status"
    
    if [ "$pod_status" = "Running" ]; then
        echo "   ✅ OAuth pod is running"
        break
    fi
    sleep 10
done

# Wait for pod to be ready
echo "   Waiting for OAuth pod to be ready..."
oc wait --for=condition=Ready pods -l app=oauth-openshift -n openshift-authentication --timeout=300s
echo ""

# Step 7: Test authentication with detailed output
echo "🔑 Step 7: Testing authentication..."

# Store current login info
current_user=$(oc whoami)
echo "   Current user: $current_user"

echo "   Attempting login as $student_name..."
echo "   Command: oc login --username=$student_name --password=*** --insecure-skip-tls-verify=true"

if oc login --username="$student_name" --password="$SHARED_PASSWORD" --insecure-skip-tls-verify=true; then
    echo "   ✅ Authentication successful!"
    
    echo "   Testing namespace access..."
    if oc get pods -n "$student_name"; then
        echo "   ✅ Can access own namespace"
    else
        echo "   ❌ Cannot access own namespace"
    fi
    
    echo "   Current user after login: $(oc whoami)"
    
    # Switch back to admin
    echo "   Switching back to admin user..."
    oc login --username="$current_user" --insecure-skip-tls-verify=true
    
else
    echo "   ❌ Authentication failed!"
    echo ""
    echo "🔍 Debugging OAuth issues..."
    
    # Check OAuth pods
    echo "   OAuth pod status:"
    oc get pods -n openshift-authentication -l app=oauth-openshift
    
    # Check OAuth configuration
    echo "   OAuth configuration:"
    oc get oauth cluster -o yaml
    
    # Check secret
    echo "   OAuth secret:"
    oc get secret htpass-secret -n openshift-config -o yaml
    
    # Check user
    echo "   User object:"
    oc get user "$student_name" -o yaml
    
    # Check identity
    echo "   Identity object:"
    oc get identity "htpasswd_provider:$student_name" -o yaml
fi

echo ""
echo "🎯 Debug Complete!"
echo "=================="
echo ""
echo "📝 Key Information:"
echo "   HTPasswd file location: $HTPASSWD_FILE"
echo "   Test student: $student_name"
echo "   Password: $SHARED_PASSWORD"
echo ""
echo "📋 Next Steps:"
echo "   1. Review the output above for any errors"
echo "   2. If authentication failed, check the OAuth pod logs:"
echo "      oc logs -n openshift-authentication -l app=oauth-openshift"
echo "   3. Keep the htpasswd file for manual testing:"
echo "      cat $HTPASSWD_FILE"
echo ""
echo "🧹 Cleanup (run manually if needed):"
echo "   oc delete namespace $student_name"
echo "   oc delete user $student_name"  
echo "   oc delete identity htpasswd_provider:$student_name"
echo "   rm -rf ${TMP_DIR}  # Remove entire temp directory"
