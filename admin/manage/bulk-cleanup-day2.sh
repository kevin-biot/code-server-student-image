#!/bin/bash
# ==================================================================
# Bulk Day 2 Cleanup Script - Admin Tool
# Cleans up failed Day 2 exercises across all student namespaces
# ==================================================================

set -euo pipefail

echo "🧹 BULK DAY 2 CLEANUP - Admin Tool"
echo "=================================================="

# Configuration
STUDENT_COUNT=${1:-36}  # Default to 36 students, can override with argument
PARALLEL_LIMIT=10  # Process 10 students at a time to avoid overwhelming cluster

# Validate admin permissions
echo "🔍 Validating admin permissions..."
if ! oc auth can-i delete deployments --all-namespaces >/dev/null 2>&1; then
    echo "❌ ERROR: Insufficient permissions. This script requires cluster-admin access."
    echo "   Current user: $(oc whoami 2>/dev/null || echo 'not logged in')"
    exit 1
fi

echo "✅ Admin permissions confirmed"
echo "   User: $(oc whoami)"
echo "   Cleaning up Day 2 artifacts for $STUDENT_COUNT students"
echo ""

# Confirmation prompt
read -rp "❓ Proceed with bulk cleanup? This will delete Day 2 resources from student01 to student$(printf "%02d" $STUDENT_COUNT). (y/N): " CONFIRM
[[ "$CONFIRM" != [yY] ]] && { echo "❌ Aborted."; exit 1; }

echo ""
echo "🚀 Starting bulk cleanup..."

# Function to cleanup individual student
cleanup_student() {
    local student_num=$1
    local namespace="student$(printf "%02d" $student_num)"
    
    echo "   📦 Cleaning $namespace..."
    
    # Check if namespace exists
    if ! oc get namespace "$namespace" >/dev/null 2>&1; then
        echo "   ⚠️  Namespace $namespace not found - skipping"
        return 0
    fi
    
    # Run cleanup for this namespace
    if oc exec -n "$namespace" deployment/code-server -- bash -c "
        cd /home/coder/workspace/labs/day3-gitops/argocd 2>/dev/null || cd /tmp
        
        # Create temporary cleanup script
        cat > /tmp/cleanup-day2.sh << 'SCRIPT_EOF'
#!/bin/bash
echo '🧹 Cleaning up Day 2 workshop artifacts from namespace...'
NAMESPACE='$namespace'
echo \"   Cleaning namespace: \$NAMESPACE\"

# Clean up Day 2 java-webapp components
oc delete deployment,service,route,imagestream java-webapp -n \$NAMESPACE --ignore-not-found 2>/dev/null || true
oc delete pipelinerun,taskrun,buildrun --all -n \$NAMESPACE --ignore-not-found 2>/dev/null || true

echo '✅ Day 2 cleanup complete - ready for Day 3 GitOps!'
SCRIPT_EOF

        chmod +x /tmp/cleanup-day2.sh
        /tmp/cleanup-day2.sh
        rm -f /tmp/cleanup-day2.sh
    " 2>/dev/null; then
        echo "   ✅ $namespace cleaned successfully"
        return 0
    else
        echo "   ⚠️  $namespace cleanup failed (code-server may not be running)"
        
        # Fallback: Direct admin cleanup
        echo "   🔧 Attempting direct admin cleanup for $namespace..."
        oc delete deployment,service,route,imagestream java-webapp -n "$namespace" --ignore-not-found 2>/dev/null || true
        oc delete pipelinerun,taskrun,buildrun --all -n "$namespace" --ignore-not-found 2>/dev/null || true
        echo "   ✅ $namespace direct cleanup completed"
        return 0
    fi
}

# Export function for parallel execution
export -f cleanup_student

# Create sequence and run in parallel batches
seq 1 "$STUDENT_COUNT" | xargs -n 1 -P "$PARALLEL_LIMIT" -I {} bash -c 'cleanup_student {}'

echo ""
echo "🎉 Bulk cleanup completed!"
echo ""

# Summary report
echo "📊 Cleanup Summary:"
echo "   • Processed: $STUDENT_COUNT student namespaces"
echo "   • Method: oc exec into code-server pods + direct admin fallback"
echo "   • Resources cleaned: Day 2 java-webapp deployments, services, routes, imagestreams"
echo "   • Pipeline artifacts: All pipelineruns, taskruns, buildruns removed"
echo ""

# Verify cleanup worked
echo "🔍 Verification (checking first 5 namespaces):"
for i in {1..5}; do
    namespace="student$(printf "%02d" $i)"
    if oc get namespace "$namespace" >/dev/null 2>&1; then
        webapp_count=$(oc get deployment java-webapp -n "$namespace" 2>/dev/null | wc -l || echo "0")
        if [[ "$webapp_count" -eq 0 ]]; then
            echo "   ✅ $namespace: Day 2 java-webapp removed"
        else
            echo "   ⚠️  $namespace: Day 2 java-webapp still present"
        fi
    fi
done

echo ""
echo "🎯 Next Steps:"
echo "   • Students can now run Day 3 GitOps exercises cleanly"
echo "   • No conflicts between Day 2 direct deployments and Day 3 GitOps"
echo "   • ArgoCD can manage java-webapp resources without conflicts"
echo ""
echo "✅ All students ready for Day 3 GitOps workshop!"
