#!/bin/bash
# Quick cluster state check
set -e

echo "🔍 Cluster Status Check"
echo "======================"

echo "👤 Current user: $(oc whoami)"
echo "🌐 Cluster: $(oc whoami --show-server)"

echo ""
echo "📦 Checking required namespaces..."
for ns in devops openshift-operators; do
    if oc get namespace "$ns" >/dev/null 2>&1; then
        echo "✅ $ns namespace exists"
    else
        echo "❌ $ns namespace missing"
    fi
done

echo ""
echo "🔧 Checking Shipwright installation..."
if oc get crd builds.shipwright.io >/dev/null 2>&1; then
    echo "✅ Shipwright CRDs found"
    if oc get pod -n shipwright-build >/dev/null 2>&1; then
        echo "✅ Shipwright pods running"
        oc get pods -n shipwright-build --no-headers | while read name status ready age; do
            echo "   $name: $status"
        done
    else
        echo "⚠️  Shipwright namespace not found - checking operators..."
    fi
else
    echo "❌ Shipwright not installed"
fi

echo ""
echo "🖼️  Checking internal registry..."
if oc get route default-route -n openshift-image-registry >/dev/null 2>&1; then
    REGISTRY_ROUTE=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}')
    echo "✅ Registry route: $REGISTRY_ROUTE"
else
    echo "⚠️  Registry route not exposed (this is normal)"
fi

echo ""
echo "🔗 Internal registry endpoint:"
echo "   image-registry.openshift-image-registry.svc:5000"
