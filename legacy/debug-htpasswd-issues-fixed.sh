#!/bin/bash
# debug-htpasswd-issues-fixed.sh - Debug version with corrected htpasswd syntax

set -e

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
START_NUM=98  # Use test students to avoid conflicts
END_NUM=98    # Test with just one student
SHARED_PASSWORD="DevOps2025!"

echo "🔍 HTPasswd and Login Issues Debug (Fixed)"
echo "=========================================="
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

# Step 2: Create and test htpasswd file with correct syntax
echo "🔐 Step 2: Creating and testing htpasswd file..."

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

echo "   🧪 Creating htpasswd file at: ${HTPASSWD_FILE}"

# Clean any existing file
rm -f "${HTPASSWD_FILE}"

# Test different htpasswd command formats
echo "   🔧 Testing htpasswd command formats..."

# Method 1: Using -c -b -B (create, batch, bcrypt)
echo "      Method 1: htpasswd -c -b -B [file] [user] [pass]"
if htpasswd -c -b -B "${HTPASSWD_FILE}" "${student_name}" "${SHARED_PASSWORD}" 2>&1; then
    echo "      ✅ Method 1 successful"
    successful_method="1"
else
    echo "      ❌ Method 1 failed"
    rm -f "${HTPASSWD_FILE}"
    
    # Method 2: Using -c -B (create, bcrypt, interactive)
    echo "      Method 2: htpasswd -c -B [file] [user] (interactive)"
    if echo "${SHARED_PASSWORD}" | htpasswd -c -B -i "${HTPASSWD_FILE}" "${student_name}" 2>&1; then
        echo "      ✅ Method 2 successful"
        successful_method="2"
    else
        echo "      ❌ Method 2 failed"
        rm -f "${HTPASSWD_FILE}"
        
        # Method 3: Using -c -b (create, batch, default MD5)
        echo "      Method 3: htpasswd -c -b [file] [user] [pass] (MD5)"
        if htpasswd -c -b "${HTPASSWD_FILE}" "${student_name}" "${SHARED_PASSWORD}" 2>&1; then
            echo "      ✅ Method 3 successful"
            successful_method="3"
        else
            echo "      ❌ Method 3 failed"
            rm -f "${HTPASSWD_FILE}"
            
            # Method 4: Manual creation (fallback)
            echo "      Method 4: Manual hash creation"
            # Create a simple htpasswd entry manually
            HASHED_PASSWORD=$(openssl passwd -apr1 "${SHARED_PASSWORD}" 2>/dev/null || echo "manual_hash_failed")
            if [ "$HASHED_PASSWORD" != "manual_hash_failed" ]; then
                echo "${student_name}:${HASHED_PASSWORD}" > "${HTPASSWD_FILE}"
                echo "      ✅ Method 4 successful (manual hash)"
                successful_method="4"
            else
                echo "      ❌ All methods failed"
                exit 1
            fi
        fi
    fi
fi

# Verify file creation
if [ -f "${HTPASSWD_FILE}" ]; then
    echo "   ✅ HTPasswd file created successfully using method $successful_method"
    
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
    echo "   ❌ Could not create htpasswd file"
    exit 1
fi
echo ""

# Step 3: Create user objects with verbose output
echo "👥 Step 3: Creating user objects..."

echo "   Creating user $student_name..."
if oc create user "$student_name" --dry-run=client -o yaml | oc apply -f -; then
    echo "   ✅ User created successfully"
    oc get user "$student_name" -o yaml | grep -E "^  name:|^  uid:" | sed 's/^/      /'
else
    echo "   ❌ Failed to create user"
    exit 1
fi

echo "   Creating identity htpasswd_provider:$student_name..."
if oc create identity "htpasswd_provider:$student_name" --dry-run=client -o yaml | oc apply -f -; then
    echo "   ✅ Identity created successfully"
    oc get identity "htpasswd_provider:$student_name" -o yaml | grep -E "^  name:|^  providerName:" | sed 's/^/      /'
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
echo "   Raw secret data:"
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

# Step 6: Wait for OAuth restart with monitoring
echo "⏳ Step 6: Restarting and monitoring OAuth services..."

echo "   Current OAuth pods:"
oc get pods -n openshift-authentication -l app=oauth-openshift

echo "   Deleting OAuth pods..."
oc delete pods -n openshift-authentication -l app=oauth-openshift

echo "   Waiting for OAuth pods to restart..."
sleep 15

echo "   Monitoring OAuth pod status..."
for i in {1..20}; do
    pod_count=$(oc get pods -n openshift-authentication -l app=oauth-openshift --no-headers 2>/dev/null | wc -l)
    ready_count=$(oc get pods -n openshift-authentication -l app=oauth-openshift --no-headers 2>/dev/null | grep "Running" | wc -l)
    
    echo "   Attempt $i/20: $ready_count/$pod_count pods running"
    
    if [ "$ready_count" -gt 0 ] && [ "$ready_count" -eq "$pod_count" ]; then
        echo "   ✅ OAuth pods are running"
        break
    fi
    sleep 10
done

# Wait for pod to be ready
echo "   Waiting for OAuth pod to be fully ready..."
if oc wait --for=condition=Ready pods -l app=oauth-openshift -n openshift-authentication --timeout=300s; then
    echo "   ✅ OAuth pods are ready"
else
    echo "   ⚠️  OAuth pods may not be fully ready yet"
fi

# Additional wait for OAuth to process the new configuration
echo "   Waiting additional 30 seconds for OAuth configuration to take effect..."
sleep 30
echo ""

# Step 7: Test authentication with detailed output
echo "🔑 Step 7: Testing authentication..."

# Store current login info
current_user=$(oc whoami)
current_server=$(oc whoami --show-server)
echo "   Current user: $current_user"
echo "   Current server: $current_server"

echo "   Attempting login as $student_name..."
echo "   Command: oc login --username=$student_name --password=*** --server=$current_server --insecure-skip-tls-verify=true"

# Try authentication
auth_success=false
if oc login --username="$student_name" --password="$SHARED_PASSWORD" --server="$current_server" --insecure-skip-tls-verify=true 2>&1; then
    echo "   ✅ Authentication successful!"
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
fi

if [ "$auth_success" = false ]; then
    echo ""
    echo "🔍 Debugging OAuth issues..."
    
    # Check OAuth pods
    echo "   OAuth pod status:"
    oc get pods -n openshift-authentication -l app=oauth-openshift -o wide
    
    # Check OAuth pod logs
    echo "   OAuth pod logs (last 20 lines):"
    oc logs -n openshift-authentication -l app=oauth-openshift --tail=20 | sed 's/^/      /'
    
    # Check OAuth configuration
    echo "   OAuth configuration:"
    oc get oauth cluster -o yaml | grep -A 10 "identityProviders:" | sed 's/^/      /'
    
    # Check secret
    echo "   OAuth secret status:"
    oc get secret htpass-secret -n openshift-config | sed 's/^/      /'
    
    # Check user
    echo "   User object:"
    oc get user "$student_name" -o yaml | grep -E "^  name:|^  uid:|^kind:|^metadata:" | sed 's/^/      /'
    
    # Check identity
    echo "   Identity object:"
    oc get identity "htpasswd_provider:$student_name" -o yaml | grep -E "^  name:|^  providerName:|^kind:" | sed 's/^/      /'
fi

echo ""
echo "🎯 Debug Complete!"
echo "=================="
echo ""
echo "📝 Key Information:"
echo "   HTPasswd file location: $HTPASSWD_FILE"
echo "   HTPasswd creation method: $successful_method"
echo "   Test student: $student_name"
echo "   Password: $SHARED_PASSWORD"
echo "   Authentication result: $([ "$auth_success" = true ] && echo "SUCCESS" || echo "FAILED")"
echo ""
echo "📋 Next Steps:"
if [ "$auth_success" = true ]; then
    echo "   ✅ HTPasswd authentication is working!"
    echo "   ✅ You can now fix your main script with the working method"
    echo ""
    echo "🔧 Apply this fix to complete-student-setup-simple.sh:"
    case "$successful_method" in
        "1") echo "   Use: htpasswd -c -b -B \"\${HTPASSWD_FILE}\" \"\${student_name}\" \"\${SHARED_PASSWORD}\"" ;;
        "2") echo "   Use: echo \"\${SHARED_PASSWORD}\" | htpasswd -c -B -i \"\${HTPASSWD_FILE}\" \"\${student_name}\"" ;;
        "3") echo "   Use: htpasswd -c -b \"\${HTPASSWD_FILE}\" \"\${student_name}\" \"\${SHARED_PASSWORD}\"" ;;
        "4") echo "   Use manual hash method (see script for details)" ;;
    esac
else
    echo "   1. Review the OAuth pod logs above for errors"
    echo "   2. Check if the htpasswd format is compatible with OpenShift"
    echo "   3. Verify OAuth provider configuration is correct"
    echo "   4. Try waiting longer for OAuth to sync the new configuration"
fi

echo ""
echo "🧹 Cleanup (run manually if needed):"
echo "   oc delete namespace $student_name"
echo "   oc delete user $student_name"  
echo "   oc delete identity htpasswd_provider:$student_name"
echo "   rm -rf $TMP_DIR"
