#!/bin/bash
# test-student-auth.sh - Test student authentication

set -e

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
SHARED_PASSWORD="DevOps2025!"

echo "🧪 Testing Student Authentication"
echo "================================"
echo ""

# Test multiple students
for student_num in 01 02 03; do
    student_name="student${student_num}"
    
    echo "Testing ${student_name}..."
    
    # Test login
    if oc login -u "${student_name}" -p "${SHARED_PASSWORD}" --insecure-skip-tls-verify=true &>/dev/null; then
        echo "   ✅ Login successful"
        
        # Test access to own namespace
        if oc get pods -n "${student_name}" &>/dev/null; then
            echo "   ✅ Can access own namespace"
        else
            echo "   ❌ Cannot access own namespace"
        fi
        
        # Test access to shared namespace
        if oc get pods -n devops &>/dev/null; then
            echo "   ✅ Can view devops namespace"
        else
            echo "   ❌ Cannot view devops namespace"
        fi
        
        # Test forbidden access
        if [ "${student_name}" != "student01" ]; then
            if oc get pods -n student01 &>/dev/null; then
                echo "   ❌ Can access other student namespace (should be forbidden)"
            else
                echo "   ✅ Cannot access other student namespace (correct)"
            fi
        fi
        
    else
        echo "   ❌ Login failed"
    fi
    
    echo ""
done

# Login back as admin
echo "🔄 Logging back in as admin..."
oc login -u kubeadmin -p $(cat ~/auth-info.txt | grep "kubeadmin" | cut -d' ' -f2) --insecure-skip-tls-verify=true &>/dev/null || true

echo "✅ Authentication test complete!"
