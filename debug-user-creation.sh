#!/bin/bash
# debug-user-creation.sh - Debug the user creation step specifically

set -e

START_NUM=98
END_NUM=98  # Just test with one user
SHARED_PASSWORD="DevOps2025!"

echo "🔍 Debugging User Creation Step"
echo "==============================="
echo "Testing with: student$(printf "%02d" $START_NUM)"
echo ""

# Clean up first
student_name=$(printf "student%02d" $START_NUM)
echo "🧹 Cleaning up previous test..."
oc delete namespace "$student_name" --ignore-not-found=true
oc delete user "$student_name" --ignore-not-found=true  
oc delete identity "htpasswd_provider:$student_name" --ignore-not-found=true
echo ""

# Create namespace (since deploy-bulk-students.sh seems to have issues)
echo "📦 Creating namespace manually..."
oc create namespace "$student_name"
echo "   ✅ Namespace created"
echo ""

# Test each user creation step individually
echo "👥 Testing user creation steps individually..."

echo "   Step 3a: Creating user object..."
echo "   Command: oc create user \"${student_name}\" --dry-run=client -o yaml | oc apply -f -"

if oc create user "${student_name}" --dry-run=client -o yaml | oc apply -f -; then
    echo "   ✅ User created successfully"
    echo "   Verifying user exists:"
    oc get user "${student_name}" -o yaml | grep -E "^  name:|^  uid:|^kind:" | sed 's/^/      /'
else
    echo "   ❌ User creation failed"
    exit 1
fi
echo ""

echo "   Step 3b: Creating identity object..."
echo "   Command: oc create identity htpasswd_provider:\"${student_name}\" --dry-run=client -o yaml | oc apply -f -"

if timeout 30 oc create identity htpasswd_provider:"${student_name}" --dry-run=client -o yaml | oc apply -f -; then
    echo "   ✅ Identity created successfully"
    echo "   Verifying identity exists:"
    oc get identity "htpasswd_provider:${student_name}" -o yaml | grep -E "^  name:|^providerName:|^providerUserName:" | sed 's/^/      /'
else
    echo "   ❌ Identity creation failed or timed out"
    echo "   Let's see what the dry-run produces:"
    oc create identity htpasswd_provider:"${student_name}" --dry-run=client -o yaml | sed 's/^/      /'
    exit 1
fi
echo ""

echo "   Step 3c: Creating user identity mapping..."
echo "   Command: oc create useridentitymapping htpasswd_provider:\"${student_name}\" \"${student_name}\" --dry-run=client -o yaml | oc apply -f -"

if timeout 30 oc create useridentitymapping htpasswd_provider:"${student_name}" "${student_name}" --dry-run=client -o yaml | oc apply -f -; then
    echo "   ✅ User identity mapping created successfully"
    echo "   Verifying mapping exists:"
    oc get useridentitymapping "htpasswd_provider:${student_name}" -o yaml | grep -E "^  name:|^kind:" | sed 's/^/      /'
else
    echo "   ❌ User identity mapping creation failed or timed out"
    echo "   Let's see what the dry-run produces:"
    oc create useridentitymapping htpasswd_provider:"${student_name}" "${student_name}" --dry-run=client -o yaml | sed 's/^/      /'
    exit 1
fi
echo ""

echo "   Step 3d: Adding RBAC permissions..."
if oc adm policy add-role-to-user admin "${student_name}" -n "${student_name}"; then
    echo "   ✅ RBAC permissions added"
else
    echo "   ❌ RBAC permissions failed"
    exit 1
fi
echo ""

echo "🎯 User Creation Debug Complete!"
echo "==============================="
echo "✅ All user creation steps completed successfully"
echo ""
echo "🧹 Cleanup (run manually):"
echo "   oc delete namespace $student_name"
echo "   oc delete user $student_name"
echo "   oc delete identity htpasswd_provider:$student_name"
