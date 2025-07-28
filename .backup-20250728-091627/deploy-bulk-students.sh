#!/bin/bash
# deploy-bulk-students.sh - Deploy multiple students for capacity testing

# set -e  # Disabled to handle AlreadyExists errors gracefully

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
START_NUM="${1:-1}"
END_NUM="${2:-25}"
BATCH_SIZE="${3:-5}"  # Deploy 5 at a time to avoid overwhelming cluster

echo "🚀 Deploying Students ${START_NUM} to ${END_NUM} (batches of ${BATCH_SIZE})"
echo "Cluster Domain: ${CLUSTER_DOMAIN}"
echo "=================================================="

# Function to deploy a student
deploy_student() {
    local student_num=$1
    local student_name=$(printf "student%02d" $student_num)
    
    echo "📦 Deploying ${student_name}..."
    oc process -f student-template.yaml \
        -p STUDENT_NAME="${student_name}" \
        -p CLUSTER_DOMAIN="${CLUSTER_DOMAIN}" \
        -p STORAGE_CLASS="gp3-csi" \
        | oc apply -f - > /dev/null
    
    echo "✅ ${student_name} submitted"
}

# Deploy in batches
current_batch=0
for i in $(seq $START_NUM $END_NUM); do
    deploy_student $i
    
    ((current_batch++))
    
    # Wait after each batch
    if [ $((current_batch % BATCH_SIZE)) -eq 0 ]; then
        echo ""
        echo "⏳ Batch complete, waiting 30s for cluster to process..."
        sleep 30
        
        echo "📊 Current cluster status:"
        oc get pods --all-namespaces | grep student | grep -E "(Pending|ContainerCreating|Running)" | wc -l
        echo "   Student pods: $(oc get pods --all-namespaces | grep student | wc -l || echo 0)"
        echo ""
    fi
done

echo ""
echo "🎉 All students deployed! Checking final status..."

# Final status check
echo "📋 Final Deployment Summary:"
echo "   Namespaces: $(oc get namespaces | grep student | wc -l)"
echo "   Pods: $(oc get pods --all-namespaces | grep code-server | wc -l)"
echo "   PVCs: $(oc get pvc --all-namespaces | grep student | wc -l)"

echo ""
echo "🔍 Check individual student status with:"
echo "   for i in {01..25}; do echo \"Student \$i:\"; oc get pods -n student\$i 2>/dev/null || echo \"Not found\"; done"

echo ""
echo "⚠️  Monitor cluster health:"
echo "   oc top nodes"
echo "   oc get events --sort-by='.lastTimestamp' | tail -20"
