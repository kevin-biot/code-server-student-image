#!/bin/bash
# comprehensive-pipeline-monitoring.sh - Detailed baseline monitoring for single pipeline

set -e

NAMESPACE=${1:-student01}
LOG_DIR="/tmp/pipeline-baseline-$(date +%Y%m%d-%H%M%S)"
MONITOR_INTERVAL=10

echo "🔍 Comprehensive Pipeline Baseline Monitoring"
echo "============================================="
echo "Namespace: $NAMESPACE"
echo "Log directory: $LOG_DIR"
echo "Monitor interval: ${MONITOR_INTERVAL}s"

mkdir -p "$LOG_DIR"

# Function to collect comprehensive metrics
collect_metrics() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local prefix="$LOG_DIR/$(date +%H%M%S)"
    
    echo "=== $timestamp ===" >> "$LOG_DIR/timeline.log"
    
    # 1. Node resource usage (oc top works!)
    echo "Node resources at $timestamp:" >> "$prefix-node-resources.log"
    oc adm top nodes >> "$prefix-node-resources.log" 2>/dev/null || echo "oc top nodes failed" >> "$prefix-node-resources.log"
    
    # 2. Pod resource usage
    echo "Pod resources at $timestamp:" >> "$prefix-pod-resources.log"
    oc adm top pods -n "$NAMESPACE" >> "$prefix-pod-resources.log" 2>/dev/null || echo "oc top pods failed" >> "$prefix-pod-resources.log"
    
    # 3. All pods in namespace with detailed status
    echo "Pod status at $timestamp:" >> "$prefix-pod-status.log"
    oc get pods -n "$NAMESPACE" -o wide >> "$prefix-pod-status.log"
    
    # 4. Resource requests/limits for all pods
    echo "Pod resource specs at $timestamp:" >> "$prefix-pod-specs.log"
    oc get pods -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].resources}{"\n"}{end}' >> "$prefix-pod-specs.log" 2>/dev/null
    
    # 5. Node resource allocation vs capacity
    echo "Node resource allocation at $timestamp:" >> "$prefix-node-allocation.log"
    for node in $(oc get nodes --no-headers -o custom-columns=":metadata.name"); do
        echo "=== Node: $node ===" >> "$prefix-node-allocation.log"
        oc describe node "$node" | grep -A 20 "Allocated resources:" >> "$prefix-node-allocation.log"
        echo "" >> "$prefix-node-allocation.log"
    done
    
    # 6. Quota usage in namespace
    echo "Quota usage at $timestamp:" >> "$prefix-quota.log"
    oc describe quota -n "$NAMESPACE" >> "$prefix-quota.log" 2>/dev/null || echo "No quota found" >> "$prefix-quota.log"
    
    # 7. Pipeline/TaskRun status
    echo "Pipeline status at $timestamp:" >> "$prefix-pipeline-status.log"
    oc get pipelineruns -n "$NAMESPACE" -o wide >> "$prefix-pipeline-status.log" 2>/dev/null || echo "No pipelineruns" >> "$prefix-pipeline-status.log"
    oc get taskruns -n "$NAMESPACE" -o wide >> "$prefix-pipeline-status.log" 2>/dev/null || echo "No taskruns" >> "$prefix-pipeline-status.log"
    
    # 8. Events in namespace
    echo "Events at $timestamp:" >> "$prefix-events.log"
    oc get events -n "$NAMESPACE" --sort-by='.lastTimestamp' >> "$prefix-events.log" 2>/dev/null
    
    # 9. Pod resource utilization details
    echo "Pod utilization details at $timestamp:" >> "$prefix-pod-details.log"
    for pod in $(oc get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name"); do
        echo "=== Pod: $pod ===" >> "$prefix-pod-details.log"
        oc describe pod "$pod" -n "$NAMESPACE" | grep -A 10 -B 5 -E "(Requests|Limits|QoS Class)" >> "$prefix-pod-details.log" 2>/dev/null
        echo "" >> "$prefix-pod-details.log"
    done
    
    # 10. Storage usage
    echo "Storage usage at $timestamp:" >> "$prefix-storage.log"
    oc get pvc -n "$NAMESPACE" >> "$prefix-storage.log" 2>/dev/null || echo "No PVCs" >> "$prefix-storage.log"
    
    # 11. Summary metrics for easy analysis
    {
        echo "TIMESTAMP: $timestamp"
        echo "CLUSTER_NODES: $(oc get nodes --no-headers | wc -l)"
        echo "NAMESPACE_PODS: $(oc get pods -n "$NAMESPACE" --no-headers | wc -l)"
        echo "RUNNING_PODS: $(oc get pods -n "$NAMESPACE" --no-headers | grep Running | wc -l)"
        echo "PENDING_PODS: $(oc get pods -n "$NAMESPACE" --no-headers | grep Pending | wc -l)"
        echo "FAILED_PODS: $(oc get pods -n "$NAMESPACE" --no-headers | grep -E '(Error|Failed|CrashLoopBackOff)' | wc -l)"
        echo "PIPELINE_RUNS: $(oc get pipelineruns -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)"
        echo "TASK_RUNS: $(oc get taskruns -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)"
    } >> "$LOG_DIR/summary-metrics.log"
}

# Function to monitor continuously
monitor_continuously() {
    echo "🔄 Starting continuous monitoring (Ctrl+C to stop)..."
    while true; do
        collect_metrics
        echo "📊 Metrics collected at $(date '+%H:%M:%S')"
        sleep "$MONITOR_INTERVAL"
    done
}

# Function to generate final report
generate_report() {
    echo "📋 Generating comprehensive report..."
    
    cat > "$LOG_DIR/baseline-report.md" << EOF
# Pipeline Baseline Monitoring Report

**Test Date**: $(date)  
**Namespace**: $NAMESPACE  
**Duration**: $(ls $LOG_DIR/*-summary.log 2>/dev/null | wc -l) samples over $(($(ls $LOG_DIR/*-summary.log 2>/dev/null | wc -l) * MONITOR_INTERVAL)) seconds

## Resource Usage Summary

### Peak Resource Usage
\`\`\`
$(grep -h "Node:" $LOG_DIR/*-node-resources.log | sort | tail -5)
\`\`\`

### Pod Resource Patterns
\`\`\`
$(grep -h "$NAMESPACE" $LOG_DIR/*-pod-resources.log | sort -k3 -nr | head -10)
\`\`\`

### Pipeline Execution Timeline
\`\`\`
$(cat "$LOG_DIR/timeline.log")
\`\`\`

## Key Metrics
- **Total Monitoring Duration**: $(($(ls $LOG_DIR/*-summary.log 2>/dev/null | wc -l) * MONITOR_INTERVAL)) seconds
- **Peak CPU Usage**: $(grep -h "Node:" $LOG_DIR/*-node-resources.log | awk '{print $2}' | sort -nr | head -1)
- **Peak Memory Usage**: $(grep -h "Node:" $LOG_DIR/*-node-resources.log | awk '{print $4}' | sort -nr | head -1)

## Files Generated
$(ls -la $LOG_DIR/ | grep -v "^total")

## Analysis
This baseline represents the resource consumption of a SINGLE optimized pipeline run.
For 25 concurrent pipelines, multiply these values by 25.

**Recommended cluster sizing**: Based on peak usage × 25 + 20% headroom
EOF

    echo "✅ Report generated: $LOG_DIR/baseline-report.md"
}

# Trap to generate report on exit
trap generate_report EXIT

echo ""
echo "🚀 Ready to monitor pipeline baseline"
echo "Instructions:"
echo "1. Start monitoring with: $0 $NAMESPACE"
echo "2. In another terminal, run your pipeline:"
echo "   cd rendered_$NAMESPACE"
echo "   oc create -f buildrun.yaml -n $NAMESPACE"
echo "   oc apply -f pipeline-run.yaml -n $NAMESPACE"
echo "3. Let this monitor run until pipeline completes"
echo "4. Press Ctrl+C to stop and generate report"
echo ""

read -p "🔄 Start monitoring now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    monitor_continuously
else
    echo "ℹ️  Monitoring not started. Run with 'y' when ready."
fi
