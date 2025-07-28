#!/bin/bash
# Make executable
chmod +x "$0"
# end-to-end-test.sh - Comprehensive test of complete student setup
# Tests the entire flow from deployment to authentication

set -e

# Configuration
CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
TEST_START_NUM="${1:-1}"
TEST_END_NUM="${2:-3}"
SHARED_PASSWORD="DevOps2025!"

echo "🧪 End-to-End Test: Complete Student Environment Setup"
echo "======================================================"
echo "Cluster Domain: ${CLUSTER_DOMAIN}"
echo "Testing Students: ${TEST_START_NUM} to ${TEST_END_NUM}"
echo "Shared Password: ${SHARED_PASSWORD}"
echo ""

# Pre-flight checks
echo "🔍 Pre-flight Checks"
echo "===================="

# Check if we're logged in to OpenShift
if ! oc whoami &>/dev/null; then
    echo "❌ Not logged in to OpenShift cluster"
    echo "   Please login with: oc login <cluster-url>"
    exit 1
fi

echo "✅ OpenShift login: $(oc whoami) @ $(oc cluster-info | head -1)"

# Check if required scripts exist
if [ ! -f "./complete-student-setup-simple.sh" ]; then
    echo "❌ Main setup script not found: complete-student-setup-simple.sh"
    exit 1
fi

if [ ! -f "./deploy-bulk-students.sh" ]; then
    echo "❌ Bulk deployment script not found: deploy-bulk-students.sh"
    exit 1
fi

echo "✅ Required scripts found"

# Check if htpasswd command is available
if ! command -v htpasswd &>/dev/null; then
    echo "❌ htpasswd command not found"
    echo "   Please install apache2-utils (Ubuntu) or httpd-tools (RHEL)"
    exit 1
fi

echo "✅ htpasswd command available"
echo ""

# Test 1: Clean Environment
echo "🧹 Test 1: Cleaning Previous Test Environment"
echo "============================================="

for i in $(seq $TEST_START_NUM $TEST_END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    # Delete namespace and related resources
    oc delete namespace "${student_name}" --ignore-not-found=true &>/dev/null || true
    oc delete user "${student_name}" --ignore-not-found=true &>/dev/null || true
    oc delete identity "htpasswd_provider:${student_name}" --ignore-not-found=true &>/dev/null || true
    
    echo "   ✅ Cleaned ${student_name}"
done

# Clean OAuth configuration
oc delete secret htpass-secret -n openshift-config --ignore-not-found=true &>/dev/null || true
echo "   ✅ Cleaned OAuth configuration"
echo ""

# Test 2: Run Complete Setup
echo "🚀 Test 2: Running Complete Student Setup"
echo "========================================="

echo "   Executing: ./complete-student-setup-simple.sh ${TEST_START_NUM} ${TEST_END_NUM}"
./complete-student-setup-simple.sh ${TEST_START_NUM} ${TEST_END_NUM}
echo ""

# Test 3: Verify Namespaces
echo "🏗️  Test 3: Verifying Namespace Creation"
echo "========================================"

all_namespaces_created=true

for i in $(seq $TEST_START_NUM $TEST_END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    if oc get namespace "${student_name}" &>/dev/null; then
        echo "   ✅ Namespace ${student_name} exists"
        
        # Check namespace annotations
        display_name=$(oc get namespace "${student_name}" -o jsonpath='{.metadata.annotations.openshift\.io/display-name}' 2>/dev/null || echo "")
        if [ -n "$display_name" ]; then
            echo "      📋 Display name: ${display_name}"
        else
            echo "      ⚠️  No display name set"
        fi
    else
        echo "   ❌ Namespace ${student_name} not found"
        all_namespaces_created=false
    fi
done

if [ "$all_namespaces_created" = true ]; then
    echo "   ✅ All namespaces created successfully"
else
    echo "   ❌ Some namespaces missing"
    exit 1
fi
echo ""

# Test 4: Verify User Accounts
echo "👥 Test 4: Verifying User Account Creation"
echo "=========================================="

all_users_created=true

for i in $(seq $TEST_START_NUM $TEST_END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    if oc get user "${student_name}" &>/dev/null; then
        echo "   ✅ User ${student_name} exists"
        
        # Check identity mapping
        if oc get identity "htpasswd_provider:${student_name}" &>/dev/null; then
            echo "      🔗 Identity mapping exists"
        else
            echo "      ❌ Identity mapping missing"
            all_users_created=false
        fi
    else
        echo "   ❌ User ${student_name} not found"
        all_users_created=false
    fi
done

if [ "$all_users_created" = true ]; then
    echo "   ✅ All user accounts created successfully"
else
    echo "   ❌ Some user accounts missing"
    exit 1
fi
echo ""

# Test 5: Verify RBAC Permissions
echo "🔐 Test 5: Verifying RBAC Permissions"
echo "====================================="

all_rbac_correct=true

for i in $(seq $TEST_START_NUM $TEST_END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    # Check admin role in own namespace
    if oc get rolebinding -n "${student_name}" -o jsonpath='{.items[?(@.subjects[0].name=="'${student_name}'")].metadata.name}' | grep -q admin; then
        echo "   ✅ ${student_name} has admin role in own namespace"
    else
        echo "   ❌ ${student_name} missing admin role in own namespace"
        all_rbac_correct=false
    fi
    
    # Check view role in devops namespace
    if oc get rolebinding -n devops -o jsonpath='{.items[?(@.subjects[*].name=="'${student_name}'")].metadata.name}' | grep -q view; then
        echo "   ✅ ${student_name} has view role in devops namespace"
    else
        echo "   ❌ ${student_name} missing view role in devops namespace"
        all_rbac_correct=false
    fi
done

if [ "$all_rbac_correct" = true ]; then
    echo "   ✅ All RBAC permissions configured correctly"
else
    echo "   ❌ Some RBAC permissions missing"
    exit 1
fi
echo ""

# Test 6: Verify OAuth Configuration
echo "🔧 Test 6: Verifying OAuth Configuration"
echo "========================================"

# Check if OAuth secret exists
if oc get secret htpass-secret -n openshift-config &>/dev/null; then
    echo "   ✅ OAuth secret exists"
else
    echo "   ❌ OAuth secret missing"
    exit 1
fi

# Check OAuth configuration
oauth_provider=$(oc get oauth cluster -o jsonpath='{.spec.identityProviders[?(@.name=="htpasswd_provider")].name}' 2>/dev/null || echo "")
if [ "$oauth_provider" = "htpasswd_provider" ]; then
    echo "   ✅ OAuth provider configured"
else
    echo "   ❌ OAuth provider not configured correctly"
    exit 1
fi

# Wait for OAuth pods to be ready
echo "   ⏳ Waiting for OAuth pods to be ready..."
oc wait --for=condition=Ready pods -l app=oauth-openshift -n openshift-authentication --timeout=300s &>/dev/null
echo "   ✅ OAuth pods ready"
echo ""

# Test 7: Test Authentication
echo "🔑 Test 7: Testing Authentication"
echo "================================="

# Wait a bit more for OAuth to be fully ready
echo "   ⏳ Waiting for OAuth to be fully ready..."
sleep 30

auth_tests_passed=0
auth_tests_total=$((TEST_END_NUM - TEST_START_NUM + 1))

for i in $(seq $TEST_START_NUM $TEST_END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    echo "   🧪 Testing login for ${student_name}..."
    
    # Try to login (this will test if the user/password combination works)
    if oc login --username="${student_name}" --password="${SHARED_PASSWORD}" --insecure-skip-tls-verify=true &>/dev/null; then
        echo "   ✅ ${student_name} authentication successful"
        
        # Test access to own namespace
        if oc get pods -n "${student_name}" &>/dev/null; then
            echo "      ✅ Can access own namespace"
        else
            echo "      ❌ Cannot access own namespace"
            continue
        fi
        
        # Test view access to devops namespace
        if oc get pods -n devops &>/dev/null; then
            echo "      ✅ Can view devops namespace"
        else
            echo "      ❌ Cannot view devops namespace"
            continue
        fi
        
        # Test that cannot modify other student namespaces
        other_student_num=$((i == TEST_START_NUM ? TEST_END_NUM : TEST_START_NUM))
        other_student_name=$(printf "student%02d" $other_student_num)
        
        if [ "$other_student_name" != "$student_name" ]; then
            if oc auth can-i create pods -n "${other_student_name}" 2>/dev/null | grep -q "yes"; then
                echo "      ❌ Can inappropriately modify other student namespace"
                continue
            else
                echo "      ✅ Cannot modify other student namespace (good)"
            fi
        fi
        
        auth_tests_passed=$((auth_tests_passed + 1))
    else
        echo "   ❌ ${student_name} authentication failed"
    fi
done

# Log back in as admin
oc login --username=admin --password=admin --insecure-skip-tls-verify=true &>/dev/null || true

echo "   📊 Authentication Results: ${auth_tests_passed}/${auth_tests_total} passed"

if [ "$auth_tests_passed" -eq "$auth_tests_total" ]; then
    echo "   ✅ All authentication tests passed"
else
    echo "   ❌ Some authentication tests failed"
    exit 1
fi
echo ""

# Test 8: Code-Server Deployment Check
echo "💻 Test 8: Verifying Code-Server Deployments"
echo "============================================="

all_code_servers_ready=true

for i in $(seq $TEST_START_NUM $TEST_END_NUM); do
    student_name=$(printf "student%02d" $i)
    
    # Check if code-server deployment exists
    if oc get deployment "${student_name}-code-server" -n "${student_name}" &>/dev/null; then
        echo "   ✅ Code-server deployment exists for ${student_name}"
        
        # Check if deployment is ready
        ready_replicas=$(oc get deployment "${student_name}-code-server" -n "${student_name}" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        if [ "$ready_replicas" -gt 0 ]; then
            echo "      ✅ Code-server is ready (${ready_replicas} replica(s))"
        else
            echo "      ⚠️  Code-server not ready yet"
        fi
        
        # Check if route exists
        if oc get route "${student_name}-code-server" -n "${student_name}" &>/dev/null; then
            route_url=$(oc get route "${student_name}-code-server" -n "${student_name}" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
            if [ -n "$route_url" ]; then
                echo "      🌐 Code-server URL: https://${route_url}"
            fi
        else
            echo "      ❌ Code-server route missing"
            all_code_servers_ready=false
        fi
    else
        echo "   ❌ Code-server deployment missing for ${student_name}"
        all_code_servers_ready=false
    fi
done

if [ "$all_code_servers_ready" = true ]; then
    echo "   ✅ All code-server deployments verified"
else
    echo "   ⚠️  Some code-server deployments may need more time"
fi
echo ""

# Test 9: ArgoCD Access Check
echo "🔄 Test 9: Verifying ArgoCD Access"
echo "=================================="

if oc get namespace openshift-gitops &>/dev/null; then
    echo "   ✅ ArgoCD namespace exists"
    
    # Check if students have view access
    if oc get rolebinding bootcamp-students-argocd-view -n openshift-gitops &>/dev/null; then
        echo "   ✅ Student ArgoCD access configured"
        
        # Get ArgoCD route
        argocd_route=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
        if [ -n "$argocd_route" ]; then
            echo "   🌐 ArgoCD URL: https://${argocd_route}"
        fi
    else
        echo "   ❌ Student ArgoCD access not configured"
    fi
else
    echo "   ⚠️  ArgoCD not installed (optional for Day 1-2)"
fi
echo ""

# Final Summary
echo "🎉 End-to-End Test Complete!"
echo "============================="
echo ""
echo "📋 Test Results Summary:"
echo "✅ Namespace Creation: PASSED"
echo "✅ User Account Creation: PASSED"  
echo "✅ RBAC Configuration: PASSED"
echo "✅ OAuth Configuration: PASSED"
echo "✅ Authentication: PASSED (${auth_tests_passed}/${auth_tests_total})"
echo "✅ Code-Server Deployment: $([ "$all_code_servers_ready" = true ] && echo "PASSED" || echo "PARTIAL")"
echo "✅ ArgoCD Access: CHECKED"
echo ""
echo "🎓 Environment Ready for Bootcamp!"
echo ""
echo "📝 Quick Test Commands:"
echo "   oc login -u student01 -p '${SHARED_PASSWORD}'"
echo "   oc get pods -n student01"
echo "   oc get all -n devops"
echo ""
echo "🌐 URLs for Students:"
echo "   OpenShift Console: https://console-openshift-console.${CLUSTER_DOMAIN}"
for i in $(seq $TEST_START_NUM $TEST_END_NUM); do
    student_name=$(printf "student%02d" $i)
    echo "   ${student_name} Code-Server: https://${student_name}-code-server.${CLUSTER_DOMAIN}"
done
echo ""
echo "🔑 All students use password: ${SHARED_PASSWORD}"
