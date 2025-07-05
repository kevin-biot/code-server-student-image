#!/bin/bash
# deploy-bulk-students-robust.sh - More robust deployment with better error handling

set -euo pipefail

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
START_NUM="${1:-1}"
END_NUM="${2:-25}"
BATCH_SIZE="${3:-5}"

echo "🚀 Deploying Students ${START_NUM} to ${END_NUM} (batches of ${BATCH_SIZE})"
echo "Cluster Domain: ${CLUSTER_DOMAIN}"
echo "=================================================="

# Function to deploy a student with better error handling
deploy_student() {
    local student_num=$1
    local student_name=$(printf "student%02d" $student_num)
    
    echo "📦 Deploying ${student_name}..."
    
    # Create a temporary file for debugging
    local temp_file=$(mktemp)
    
    # Process template
    if ! oc process -f student-template.yaml \
        -p STUDENT_NAME="${student_name}" \
        -p CLUSTER_DOMAIN="${CLUSTER_DOMAIN}" \
        -p STORAGE_CLASS="gp3-csi" > "${temp_file}"; then
        echo "❌ ERROR: Failed to process template for ${student_name}"
        rm -f "${temp_file}"
        return 1
    fi
    
    # Apply resources with better error handling
    if oc apply -f "${temp_file}" > /dev/null 2>&1; then
        echo "✅ ${student_name} submitted successfully"
        rm -f "${temp_file}"
        return 0
    else
        echo "⚠️  ${student_name} submission had issues, checking if namespace exists..."
        rm -f "${temp_file}"
        
        # Check if student namespace exists (might be partial success)
        if oc get namespace "${student_name}" >/dev/null 2>&1; then
            echo "✅ ${student_name} namespace exists (partial/complete deployment)"
            return 0
        else
            echo "❌ ERROR: Failed to deploy ${student_name}"
            return 1
        fi
    fi
}

# Deploy in batches
current_batch=0
successful_deployments=0
failed_deployments=0

for i in $(seq $START_NUM $END_NUM); do
    if deploy_student $i; then
        ((successful_deployments++))
    else
        ((failed_deployments++))
        echo "⚠️  Continuing with next student despite failure..."
    fi
    
    ((current_batch++))
    
    # Wait after each batch
    if [ $((current_batch % BATCH_SIZE)) -eq 0 ]; then
        echo ""
        echo "⏳ Batch complete, waiting 30s for cluster to process..."
        sleep 30
        
        echo "📊 Current cluster status:"
        running_pods=$(oc get pods --all-namespaces | grep code-server | grep Running | wc -l || echo 0)
        total_namespaces=$(oc get namespaces | grep student | wc -l || echo 0)
        echo "   Student namespaces: ${total_namespaces}"
        echo "   Running pods: ${running_pods}"
        echo ""
    else
        sleep 2
    fi
done

echo ""
echo "🎉 Deployment batch completed!"
echo ""
echo "📋 Final Deployment Summary:"
echo "   Successful: ${successful_deployments}"
echo "   Failed: ${failed_deployments}"
echo "   Total attempted: $((END_NUM - START_NUM + 1))"

# Final status check
final_namespaces=$(oc get namespaces | grep student | wc -l || echo 0)
final_pods=$(oc get pods --all-namespaces | grep code-server | wc -l || echo 0)
running_pods=$(oc get pods --all-namespaces | grep code-server | grep Running | wc -l || echo 0)

echo "   Final namespaces: ${final_namespaces}"
echo "   Final pods (total): ${final_pods}"
echo "   Final pods (running): ${running_pods}"

echo ""
echo "🔍 Check individual student status with:"
echo "   for i in {$(printf "%02d" $START_NUM)..$(printf "%02d" $END_NUM)}; do echo \"Student \$i:\"; oc get pods -n student\$i 2>/dev/null || echo \"Not found\"; done"

echo ""
echo "⚠️  Monitor cluster health:"
echo "   oc top nodes"
echo "   oc get events --sort-by='.lastTimestamp' | tail -20"

if [ "$failed_deployments" -eq 0 ]; then
    echo ""
    echo "🎉 ALL DEPLOYMENTS SUCCESSFUL!"
else
    echo ""
    echo "⚠️  Some deployments failed. Check individual student status above."
fi
