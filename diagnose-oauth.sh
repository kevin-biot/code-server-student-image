#!/bin/bash
# diagnose-oauth.sh - Diagnose OAuth authentication issues

echo "🔍 OAuth Authentication Diagnostics"
echo "=================================="
echo ""

# Check if we're logged in as admin
echo "1. Current user context:"
oc whoami 2>/dev/null || echo "   ❌ Not logged in or no access"
echo ""

# Check OAuth configuration
echo "2. OAuth configuration:"
oc get oauth cluster -o yaml 2>/dev/null || echo "   ❌ Cannot access OAuth config"
echo ""

# Check htpasswd secret
echo "3. htpasswd secret:"
oc get secret htpass-secret -n openshift-config 2>/dev/null || echo "   ❌ htpass-secret not found"
echo ""

# Check OAuth pods
echo "4. OAuth pods status:"
oc get pods -n openshift-authentication -l app=oauth-openshift 2>/dev/null || echo "   ❌ Cannot access OAuth pods"
echo ""

# Check if student users exist
echo "5. Student users:"
oc get users | grep student 2>/dev/null || echo "   ❌ No student users found"
echo ""

# Check if student namespaces exist
echo "6. Student namespaces:"
oc get namespaces | grep student 2>/dev/null || echo "   ❌ No student namespaces found"
echo ""

# Check identity mappings
echo "7. Identity mappings:"
oc get identity | grep htpasswd_provider 2>/dev/null || echo "   ❌ No htpasswd identities found"
echo ""

echo "8. UserIdentityMappings:"
oc get useridentitymapping | grep htpasswd_provider 2>/dev/null || echo "   ❌ No htpasswd user identity mappings found"
echo ""

echo "🔍 Diagnosis complete!"
