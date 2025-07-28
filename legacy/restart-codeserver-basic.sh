#!/bin/bash
# ==================================================================
# Enhanced Code-Server Restart Script - Safe & Controlled
# NOW INCLUDES: Ghost node PVC detection and cleanup
# Addresses cluster resource limits and PVC node locking issues
# ==================================================================

set -euo pipefail

echo "🔄 BULK CODE-SERVER RESTART - Safe Restart Tool"
echo "=============================================="

# Configuration
BATCH_SIZE=${1:-3}          # Process 3 at a time (safer default)
WAIT_BETWEEN_BATCHES=${2:-120}  # Wait 2 minutes between batches
MAX_WAIT_TIMEOUT=900        # 15 minute timeout per deployment
FORCE_DELETE_TIMEOUT=180    # Force delete stuck pods after 3 minutes
FORCE_IMAGE_PULL=true       # Always force fresh image pulls

echo "⚙️  Configuration:"
echo "   • Batch size: $BATCH_SIZE deployments per batch"
echo "   • Wait between batches: ${WAIT_BETWEEN_BATCHES}s"
echo "   • Max timeout per deployment: ${MAX_WAIT_TIMEOUT}s"
echo "   • Force delete timeout: ${FORCE_DELETE_TIMEOUT}s"
echo "   • Image pull policy: Always pull fresh (avoid cache issues)"
echo

# Validate admin permissions
echo "🔍 Validating admin permissions..."
if ! oc auth can-i delete pods --all-namespaces >/dev/null 2>&1; then
    echo "❌ ERROR: Insufficient permissions. This script requires cluster-admin access."
    echo "   Current user: $(oc whoami 2>/dev/null || echo 'not logged in')"
    exit 1
fi

echo "✅ Admin permissions confirmed"
echo "   User: $(oc whoami)"
echo

# Find all code-server deployments
echo "🔍 Step 1: Finding code-server deployments..."
DEPLOYMENTS=$(oc get deployments -A -l app=code-server -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' 2>/dev/null || echo "")

if [[ -z "$DEPLOYMENTS" ]]; then
    echo "❌ No code-server deployments found"
    echo "   Looking for deployments with label: app=code-server"
    echo "   Available deployments:"
    oc get deployments -A | grep -i code || echo "   No deployments found containing 'code'"
    exit 1
fi

# Count total deployments
TOTAL_COUNT=$(echo "$DEPLOYMENTS" | grep -c '^[^[:space:]]*/' || echo "0")
echo "📋 Found $TOTAL_COUNT code-server deployments:"
while IFS= read -r deployment; do
    if [[ -n "$deployment" ]]; then
        namespace=$(echo "$deployment" | cut -d'/' -f1)
        name=$(echo "$deployment" | cut -d'/' -f2)
        
        # Check current pod status
        pod_status=$(oc get pods -n "$namespace" -l app=code-server --no-headers 2>/dev/null | awk '{print $3}' | head -1 || echo "NotFound")
        echo "   📦 $namespace/$name (Status: $pod_status)"
    fi
done <<< "$DEPLOYMENTS"

echo
read -rp "❓ Proceed with controlled restart of $TOTAL_COUNT deployments? (y/N): " CONFIRM
[[ "$CONFIRM" != [yY] ]] && { echo "❌ Aborted."; exit 1; }

echo
echo "🚀 Starting controlled batch restart..."

# Function to check and resolve PVC issues
check_and_fix_pvc_issues() {
    local namespace=$1
    local name=$2
    
    echo "      🔍 Checking PVC and node affinity issues..."
    
    # Get current pod and its node
    current_pod=$(oc get pods -n "$namespace" -l app=code-server --no-headers -o custom-columns=":metadata.name" 2>/dev/null | head -1 || echo "")
    current_node=""
    if [[ -n "$current_pod" ]]; then
        current_node=$(oc get pod "$current_pod" -n "$namespace" -o jsonpath='{.spec.nodeName}' 2>/dev/null || echo "")
    fi
    
    # Check PVC status and node affinity
    pvcs=$(oc get pvc -n "$namespace" -l app=code-server --no-headers 2>/dev/null || echo "")
    if [[ -n "$pvcs" ]]; then
        while IFS= read -r pvc_line; do
            if [[ -n "$pvc_line" ]]; then
                pvc_name=$(echo "$pvc_line" | awk '{print $1}')
                pvc_status=$(echo "$pvc_line" | awk '{print $2}')
                
                if [[ "$pvc_status" == "Bound" ]]; then
                    # Get PV and check node affinity
                    pv_name=$(oc get pvc "$pvc_name" -n "$namespace" -o jsonpath='{.spec.volumeName}' 2>/dev/null || echo "")
                    if [[ -n "$pv_name" ]]; then
                        # Check if PV has node affinity that might conflict
                        node_affinity=$(oc get pv "$pv_name" -o jsonpath='{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}' 2>/dev/null || echo "")
                        
                        if [[ -n "$node_affinity" && -n "$current_node" && "$node_affinity" != "$current_node" ]]; then
                            echo "      ⚠️  PVC $pvc_name bound to node $node_affinity, but pod on $current_node"
                            echo "      🔧 Node affinity mismatch detected - will need pod rescheduling"
                            return 1  # Indicates PVC issue found
                        fi
                    fi
                else
                    echo "      ⚠️  PVC $pvc_name status: $pvc_status"
                    return 1  # PVC not properly bound
                fi
            fi
        done <<< "$pvcs"
    fi
    
    return 0  # No PVC issues detected
}

# Function to force resolve PVC issues
force_resolve_pvc_issues() {
    local namespace=$1
    local name=$2
    
    echo "      🚨 Attempting to resolve PVC issues..."
    
    # Strategy 1: Scale down deployment completely to release PVC locks
    echo "      📉 Scaling deployment to 0 to release PVC locks..."
    oc scale deployment "$name" -n "$namespace" --replicas=0 >/dev/null 2>&1 || true
    
    # Wait for all pods to terminate
    local wait_count=0
    while [[ $(oc get pods -n "$namespace" -l app=code-server --no-headers 2>/dev/null | wc -l) -gt 0 ]]; do
        sleep 5
        ((wait_count += 5))
        if [[ $wait_count -ge 60 ]]; then
            echo "      🔨 Force deleting remaining pods..."
            oc delete pods -n "$namespace" -l app=code-server --grace-period=0 --force >/dev/null 2>&1 || true
            break
        fi
    done
    
    # Strategy 2: Wait for volume detachment
    echo "      ⏳ Waiting for volume detachment to complete..."
    sleep 15
    
    # Strategy 3: Scale back up
    echo "      📈 Scaling deployment back to 1 replica..."
    oc scale deployment "$name" -n "$namespace" --replicas=1 >/dev/null 2>&1 || true
    
    return 0
}

# Function to safely restart a single deployment
safe_restart_deployment() {
    local namespace=$1
    local name=$2
    local batch_num=$3
    local item_num=$4
    
    echo "   🔄 [$batch_num] Restarting $namespace/$name ($item_num)"
    
    # Step 1: Check for stuck resources
    echo "      🔍 Checking for stuck resources..."
    stuck_pods=$(oc get pods -n "$namespace" -l app=code-server --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l || echo "0")
    if [[ "$stuck_pods" -gt 0 ]]; then
        echo "      🧹 Cleaning up $stuck_pods failed pods..."
        oc delete pods -n "$namespace" -l app=code-server --field-selector=status.phase=Failed --grace-period=0 --force >/dev/null 2>&1 || true
    fi
    
    # Step 2: Get current pod for monitoring
    current_pod=$(oc get pods -n "$namespace" -l app=code-server --no-headers -o custom-columns=":metadata.name" 2>/dev/null | head -1 || echo "")
    
    # Step 3: Check for PVC issues
    if ! check_and_fix_pvc_issues "$namespace" "$name"; then
        echo "      ⚠️  PVC issues detected, attempting resolution..."
        force_resolve_pvc_issues "$namespace" "$name"
    fi
    
    # Step 4: Force fresh image pull by deleting pod directly
    echo "      🔄 Forcing fresh image pull..."
    
    # Delete current pod to force recreation with fresh image
    if [[ -n "$current_pod" ]]; then
        echo "      🗑️  Deleting current pod to force fresh image pull..."
        if oc delete pod "$current_pod" -n "$namespace" --grace-period=0 >/dev/null 2>&1; then
            echo "      ✅ Pod deleted, deployment will recreate with fresh image"
        else
            echo "      ⚠️  Failed to delete pod, trying force delete..."
            oc delete pod "$current_pod" -n "$namespace" --grace-period=0 --force >/dev/null 2>&1 || true
        fi
    else
        # No current pod, trigger rollout restart
        echo "      🔄 No current pod found, triggering rollout restart..."
        oc rollout restart deployment/"$name" -n "$namespace" >/dev/null 2>&1 || true
    fi
    
    # Step 5: Wait for new pod to be ready
    echo "      ⏳ Waiting for new pod to be ready..."
    if timeout ${MAX_WAIT_TIMEOUT} oc rollout status deployment/"$name" -n "$namespace" >/dev/null 2>&1; then
        # Verify pod is actually running
        new_pod_status=$(oc get pods -n "$namespace" -l app=code-server --no-headers 2>/dev/null | awk '{print $3}' | head -1 || echo "Unknown")
        if [[ "$new_pod_status" == "Running" ]]; then
            echo "      ✅ $namespace/$name restart completed successfully"
            return 0
        else
            echo "      ⚠️  $namespace/$name pod status: $new_pod_status"
            return 1
        fi
    else
        echo "      ❌ $namespace/$name restart timed out"
        
        # Cleanup if restart failed
        echo "      🧹 Cleaning up failed restart..."
        oc delete pods -n "$namespace" -l app=code-server --grace-period=0 --force >/dev/null 2>&1 || true
        sleep 10
        return 1
    fi
}

# Process deployments in batches
batch_num=1
item_count=0
success_count=0
failed_count=0

# Process deployments line by line (portable approach)
while IFS= read -r deployment; do
    if [[ -n "$deployment" ]]; then
        namespace=$(echo "$deployment" | cut -d'/' -f1)
        name=$(echo "$deployment" | cut -d'/' -f2)
        
        ((item_count++))
        
        # Start new batch if needed
        if [[ $(((item_count - 1) % BATCH_SIZE)) -eq 0 ]] && [[ $item_count -gt 1 ]]; then
            ((batch_num++))
            echo
            echo "⏸️  Batch $((batch_num - 1)) completed. Waiting ${WAIT_BETWEEN_BATCHES}s before next batch..."
            echo "   📊 Cluster resource cool-down period..."
            sleep "$WAIT_BETWEEN_BATCHES"
            echo
        fi
        
        # Display batch header
        if [[ $(((item_count - 1) % BATCH_SIZE)) -eq 0 ]]; then
            echo "🔄 Batch $batch_num: Processing items $item_count-$(( item_count + BATCH_SIZE - 1 > TOTAL_COUNT ? TOTAL_COUNT : item_count + BATCH_SIZE - 1 ))"
        fi
        
        # Restart deployment
        if safe_restart_deployment "$namespace" "$name" "$batch_num" "$item_count"; then
            ((success_count++))
        else
            ((failed_count++))
        fi
        
        # Small delay between items in same batch (allow scheduling)
        sleep 10
    fi
done <<< "$DEPLOYMENTS"

echo
echo "🎉 Bulk restart completed!"
echo
echo "📊 Final Summary:"
echo "   • Total deployments: $TOTAL_COUNT"
echo "   • Successfully restarted: $success_count"
echo "   • Failed restarts: $failed_count"
echo "   • Batches processed: $batch_num"
echo "   • Batch size: $BATCH_SIZE"
echo

# Final verification
echo "🔍 Final Verification (first 5 namespaces):"
for i in {1..5}; do
    namespace="student$(printf "%02d" $i)"
    if oc get namespace "$namespace" >/dev/null 2>&1; then
        pod_status=$(oc get pods -n "$namespace" -l app=code-server --no-headers 2>/dev/null | awk '{print $3}' | head -1 || echo "NotFound")
        pod_name=$(oc get pods -n "$namespace" -l app=code-server --no-headers -o custom-columns=":metadata.name" 2>/dev/null | head -1 || echo "none")
        if [[ "$pod_status" == "Running" ]]; then
            echo "   ✅ $namespace: $pod_name ($pod_status)"
        else
            echo "   ⚠️  $namespace: $pod_name ($pod_status)"
        fi
    fi
done

echo
echo "🎯 Next Steps:"
echo "   • All code-server pods should be running with latest image"
echo "   • Students will have access to updated environment"
echo "   • Monitor cluster resources for stability"
echo
echo "🔧 Troubleshooting commands:"
echo "   # Check all code-server pod status:"
echo "   oc get pods -A -l app=code-server"
echo
echo "   # Verify fresh image pulls (should see 'Pulling' not 'already present'):"
echo "   oc describe pods -A -l app=code-server | grep -E '(Pulling|Pulled|already present)'"
echo
echo "   # Check image versions across nodes:"
echo "   oc get pods -A -l app=code-server -o wide"
echo
echo "   # Force individual pod restart (bypasses cache):"
echo "   oc delete pod POD_NAME -n NAMESPACE --grace-period=0"
echo
echo "   # Fix specific PVC issues:"
echo "   # 1. Scale down deployment to release PVC:"
echo "   oc scale deployment/code-server -n studentXX --replicas=0"
echo "   # 2. Wait 30 seconds, then scale back up:"
echo "   oc scale deployment/code-server -n studentXX --replicas=1"
echo
echo "   # Check node affinity conflicts:"
echo "   oc get pv -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]"
echo
echo "   # Emergency PVC cleanup (DANGEROUS - data loss):"
echo "   # oc delete pvc --all -n studentXX"
echo "   # oc delete deployment code-server -n studentXX"
echo "   # Re-run student setup script"
echo
echo "✅ Controlled restart process complete!"
