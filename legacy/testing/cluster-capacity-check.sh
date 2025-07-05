#!/bin/bash
# cluster-capacity-check.sh - Check cluster capacity for 25 students

set -e

echo "🔍 Cluster Capacity Assessment for 25 Students"
echo "=============================================="

# Current cluster resources
echo "📊 Current Cluster Resources:"
oc describe nodes | grep -A 5 "Allocated resources"

# Calculate student resource requirements
STUDENTS=25
CPU_PER_STUDENT="200m"  # Request
CPU_LIMIT_PER_STUDENT="1000m"  # Limit
MEMORY_PER_STUDENT="1Gi"  # Request
MEMORY_LIMIT_PER_STUDENT="2Gi"  # Limit
STORAGE_PER_STUDENT="1Gi"

echo ""
echo "📈 Resource Requirements for ${STUDENTS} Students:"
echo "   CPU Requests: $((25 * 200))m = 5000m (5 cores)"
echo "   CPU Limits: $((25 * 1000))m = 25000m (25 cores)"
echo "   Memory Requests: $((25 * 1))Gi = 25Gi"
echo "   Memory Limits: $((25 * 2))Gi = 50Gi"
echo "   Storage: $((25 * 1))Gi = 25Gi"

echo ""
echo "🎯 Recommended Monitoring During Deployment:"
echo "   watch 'oc get nodes && oc top nodes'"
echo "   oc get events --sort-by='.lastTimestamp' | tail -20"

# Check available storage classes
echo ""
echo "💾 Available Storage:"
oc get storageclass
oc get pv | grep Available | wc -l
echo "   Available PVs: $(oc get pv | grep Available | wc -l || echo 0)"

# Check current student deployments
echo ""
echo "👥 Current Student Deployments:"
oc get namespaces | grep student | wc -l
echo "   Existing students: $(oc get namespaces | grep student | wc -l || echo 0)"

echo ""
echo "⚠️  Watch for:"
echo "   - Pod scheduling failures"
echo "   - Node resource exhaustion"
echo "   - PVC binding delays"
echo "   - Image pull timeouts"
