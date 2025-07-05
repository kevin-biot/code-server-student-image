#!/bin/bash
# monitor-25-student-deployment.sh - Real-time monitoring during bulk deployment

set -e

echo "📊 25-Student Deployment Monitoring Dashboard"
echo "============================================="

monitor_deployment() {
    while true; do
        clear
        echo "📊 25-Student Deployment Monitoring - $(date)"
        echo "=============================================="
        
        # Namespace count
        NAMESPACE_COUNT=$(oc get namespaces | grep student | wc -l || echo 0)
        echo "📦 Namespaces Created: ${NAMESPACE_COUNT}/25"
        
        # Pod status summary
        echo ""
        echo "🔄 Pod Status Summary:"
        POD_RUNNING=$(oc get pods --all-namespaces | grep code-server | grep Running | wc -l || echo 0)
        POD_PENDING=$(oc get pods --all-namespaces | grep code-server | grep Pending | wc -l || echo 0)
        POD_CREATING=$(oc get pods --all-namespaces | grep code-server | grep ContainerCreating | wc -l || echo 0)
        POD_PULL=$(oc get pods --all-namespaces | grep code-server | grep ImagePullBackOff | wc -l || echo 0)
        POD_ERROR=$(oc get pods --all-namespaces | grep code-server | grep Error | wc -l || echo 0)
        
        echo "   ✅ Running: ${POD_RUNNING}/25"
        echo "   ⏳ Pending: ${POD_PENDING}"
        echo "   🔄 Creating: ${POD_CREATING}"
        echo "   📥 Image Pull Issues: ${POD_PULL}"
        echo "   ❌ Errors: ${POD_ERROR}"
        
        # PVC status
        echo ""
        echo "💾 Storage Status:"
        PVC_BOUND=$(oc get pvc --all-namespaces | grep student | grep Bound | wc -l || echo 0)
        PVC_PENDING=$(oc get pvc --all-namespaces | grep student | grep Pending | wc -l || echo 0)
        echo "   ✅ PVCs Bound: ${PVC_BOUND}/50"  # 2 PVCs per student
        echo "   ⏳ PVCs Pending: ${PVC_PENDING}"
        
        # Node resource usage
        echo ""
        echo "🖥️  Node Resource Usage:"
        oc top nodes --no-headers | while read node cpu_usage cpu_capacity memory_usage memory_capacity; do
            echo "   ${node}: CPU: ${cpu_usage}/${cpu_capacity}, Memory: ${memory_usage}/${memory_capacity}"
        done
        
        # Recent events (errors only)
        echo ""
        echo "⚠️  Recent Issues (if any):"
        oc get events --sort-by=".lastTimestamp" | grep -E "(Failed|Error|Warning)" | tail -3 || echo "   No recent issues"
        
        # Success criteria check
        echo ""
        if [ "${POD_RUNNING}" -eq 25 ] && [ "${PVC_BOUND}" -eq 50 ]; then
            echo "🎉 SUCCESS: All 25 students deployed and running!"
            echo "✅ Ready for capacity validation testing"
            break
        elif [ "${POD_ERROR}" -gt 0 ] || [ "${POD_PULL}" -gt 5 ]; then
            echo "⚠️  ATTENTION: Issues detected that may require intervention"
        else
            echo "⏳ Deployment in progress... (${POD_RUNNING}/25 running)"
        fi
        
        echo ""
        echo "Press Ctrl+C to exit monitoring"
        sleep 15
    done
}

# Start monitoring
monitor_deployment
