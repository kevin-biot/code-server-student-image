#!/bin/bash
# audit-hardcoded-values.sh - Find hardcoded values that need to be parameterized

set -e

echo "🔍 Auditing Scripts for Hardcoded Values"
echo "========================================"

# Function to check for hardcoded values in files
audit_file() {
    local file=$1
    echo ""
    echo "📄 Checking: $file"
    
    # Check for hardcoded domains
    grep -n "bootcamp.*tkmind" "$file" 2>/dev/null && echo "   ⚠️  Hardcoded domain found" || true
    
    # Check for hardcoded namespaces
    grep -n -E "(devops|student01|openshift-gitops)" "$file" 2>/dev/null && echo "   ⚠️  Hardcoded namespace found" || true
    
    # Check for hardcoded GitHub repos
    grep -n "kevin-biot" "$file" 2>/dev/null && echo "   ⚠️  Personal GitHub repo found" || true
    
    # Check for hardcoded registry URLs
    grep -n "image-registry.openshift-image-registry" "$file" 2>/dev/null && echo "   ⚠️  Hardcoded registry found" || true
    
    # Check for hardcoded cluster names
    grep -n "crc.testing\|bootcamp-ocs-cluster" "$file" 2>/dev/null && echo "   ⚠️  Hardcoded cluster name found" || true
}

echo "🔎 Checking all script files..."

# Check all shell scripts
for script in *.sh; do
    if [ -f "$script" ]; then
        audit_file "$script"
    fi
done

# Check templates
for template in *.yaml; do
    if [ -f "$template" ]; then
        audit_file "$template"
    fi
done

# Check Dockerfile
if [ -f "Dockerfile" ]; then
    audit_file "Dockerfile"
fi

echo ""
echo "🎯 Values that need parameterization:"
echo "   1. Cluster domain (currently: bootcamp-ocs-cluster.bootcamp.tkmind.net)"
echo "   2. GitHub organization (currently: kevin-biot)"
echo "   3. Image registry (currently: image-registry.openshift-image-registry.svc:5000)"
echo "   4. Default namespaces (devops, openshift-gitops)"
echo ""
echo "💡 Recommended approach:"
echo "   - Create config file with environment-specific values"
echo "   - Use environment variables in scripts"
echo "   - Template-based configuration"

echo ""
echo "📋 Repository Migration Checklist:"
echo "   □ Move repos from kevin-biot to company GitHub"
echo "   □ Update all GitHub URLs in scripts"
echo "   □ Update Shipwright build source URLs"
echo "   □ Test builds with new repository URLs"
echo "   □ Update documentation with new URLs"
