#!/bin/bash
# 10-openshift-login.sh - Auto-login to OpenShift if credentials are available

if [ -n "$OPENSHIFT_TOKEN" ] && [ -n "$OPENSHIFT_SERVER" ]; then
    oc login --token="$OPENSHIFT_TOKEN" --server="$OPENSHIFT_SERVER" --insecure-skip-tls-verify=true
    oc project "$STUDENT_NAMESPACE" 2>/dev/null || echo "Note: Project $STUDENT_NAMESPACE not found"
fi
