#!/bin/bash
# quick-namespace-test.sh - Test if namespace creation works

echo "🧪 Quick Namespace Test"
echo "======================="

# Test creating a simple namespace
test_namespace="test-namespace-$(date +%s)"
echo "Creating test namespace: $test_namespace"

if oc create namespace "$test_namespace"; then
    echo "✅ Namespace creation works"
    
    # Test if we can create resources in it
    if oc run test-pod --image=busybox --restart=Never -n "$test_namespace" --dry-run=client -o yaml > /dev/null; then
        echo "✅ Resource creation in namespace works"
    else
        echo "❌ Cannot create resources in namespace"
    fi
    
    # Clean up
    oc delete namespace "$test_namespace"
    echo "✅ Cleanup complete"
else
    echo "❌ Namespace creation failed"
    echo "This might indicate a cluster connectivity or permissions issue"
fi
