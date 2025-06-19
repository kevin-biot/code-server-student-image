#!/bin/bash
# test-deployment.sh - Quick test to validate student deployment

set -e

STUDENT_NAME=${1:-"student01"}

echo "🔍 Testing deployment for ${STUDENT_NAME}..."

# Check namespace exists
if ! oc get namespace "${STUDENT_NAME}" >/dev/null 2>&1; then
    echo "❌ Namespace ${STUDENT_NAME} does not exist"
    exit 1
fi

echo "✅ Namespace exists"

# Check deployment
DEPLOYMENT_STATUS=$(oc get deployment code-server -n "${STUDENT_NAME}" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)
if [[ "${DEPLOYMENT_STATUS}" != "True" ]]; then
    echo "❌ Deployment not available"
    oc get deployment code-server -n "${STUDENT_NAME}"
    exit 1
fi

echo "✅ Deployment is available"

# Check pod status
POD_STATUS=$(oc get pods -l app=code-server -n "${STUDENT_NAME}" --no-headers | awk '{print $3}')
if [[ "${POD_STATUS}" != "Running" ]]; then
    echo "❌ Pod not running: ${POD_STATUS}"
    oc get pods -l app=code-server -n "${STUDENT_NAME}"
    exit 1
fi

echo "✅ Pod is running"

# Check service endpoints
ENDPOINTS=$(oc get endpoints code-server -n "${STUDENT_NAME}" -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
if [[ -z "${ENDPOINTS}" ]]; then
    echo "❌ No service endpoints"
    oc get endpoints code-server -n "${STUDENT_NAME}"
    exit 1
fi

echo "✅ Service has endpoints: ${ENDPOINTS}"

# Check route
ROUTE_URL=$(oc get route code-server -n "${STUDENT_NAME}" -o jsonpath='{.spec.host}' 2>/dev/null)
if [[ -z "${ROUTE_URL}" ]]; then
    echo "❌ No route found"
    exit 1
fi

echo "✅ Route exists: https://${ROUTE_URL}"

# Test HTTP connectivity
echo "🌐 Testing HTTP connectivity..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -k "https://${ROUTE_URL}" --max-time 10 || echo "000")
if [[ "${HTTP_STATUS}" == "200" ]]; then
    echo "✅ HTTP connectivity successful"
elif [[ "${HTTP_STATUS}" == "302" ]] || [[ "${HTTP_STATUS}" == "401" ]]; then
    echo "✅ HTTP connectivity successful (redirect/auth: ${HTTP_STATUS})"
else
    echo "⚠️  HTTP connectivity issue: ${HTTP_STATUS}"
fi

# Summary
echo ""
echo "📊 Summary for ${STUDENT_NAME}:"
echo "   Namespace: ✅"
echo "   Deployment: ✅" 
echo "   Pod: ✅"
echo "   Service: ✅"
echo "   Route: ✅"
echo "   URL: https://${ROUTE_URL}"
echo ""
echo "🎉 ${STUDENT_NAME} deployment is working correctly!"
