#!/bin/bash
# automated-pipeline-load-test.sh - Test concurrent pipeline execution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/tmp/pipeline-load-test-$(date +%Y%m%d-%H%M%S)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Automated pipeline load testing for workshop validation

Options:
    -s, --students NUM      Number of students to test (default: 5)
    -w, --waves NUM         Number of waves (default: 1) 
    -d, --delay SECONDS     Delay between waves (default: 0)
    -m, --monitor           Monitor resource usage during test
    -c, --cleanup           Clean up test pipelines after completion
    -h, --help              Show this help

Examples:
    $0 -s 5                 # Test 5 students
    $0 -s 25 -m -c          # Full load test with monitoring and cleanup
    $0 -s 10 -w 3 -d 30     # 10 students in 3 waves, 30s apart
EOF
}

# Default values
STUDENT_COUNT=5
WAVES=1
DELAY=0
MONITOR=false
CLEANUP=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--students) STUDENT_COUNT="$2"; shift 2;;
        -w|--waves) WAVES="$2"; shift 2;;
        -d|--delay) DELAY="$2"; shift 2;;
        -m|--monitor) MONITOR=true; shift;;
        -c|--cleanup) CLEANUP=true; shift;;
        -h|--help) usage; exit 0;;
        *) error "Unknown option $1"; usage; exit 1;;
    esac
done

mkdir -p "$LOG_DIR"

log "🧪 Starting Pipeline Load Test"
log "📊 Configuration:"
log "   Students: $STUDENT_COUNT"
log "   Waves: $WAVES" 
log "   Delay: ${DELAY}s"
log "   Monitor: $MONITOR"
log "   Cleanup: $CLEANUP"
log "   Log dir: $LOG_DIR"

# Check available students
AVAILABLE_STUDENTS=$(oc get namespaces -l student --no-headers -o custom-columns=":metadata.name" | head -n "$STUDENT_COUNT")
ACTUAL_COUNT=$(echo "$AVAILABLE_STUDENTS" | wc -l)

if [[ $ACTUAL_COUNT -lt $STUDENT_COUNT ]]; then
    warn "Only $ACTUAL_COUNT students available, using those instead of $STUDENT_COUNT"
    STUDENT_COUNT=$ACTUAL_COUNT
fi

log "✅ Found $STUDENT_COUNT student namespaces"

# Function to create pipeline run
create_pipeline_run() {
    local namespace=$1
    local wave=$2
    
    local run_name="java-webapp-loadtest-w${wave}-$(date +%s)"
    
    # Create pipeline run
    cat << EOF | oc apply -n "$namespace" -f - > "$LOG_DIR/${namespace}-wave${wave}.log" 2>&1
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: $run_name
  namespace: $namespace
spec:
  pipelineRef:
    name: java-webapp-pipeline
  params:
    - name: git-url
      value: https://github.com/kevin-biot/devops-workshop.git
    - name: git-revision
      value: dev
    - name: build-name
      value: java-webapp-build
    - name: namespace
      value: $namespace
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: shared-pvc
EOF
    
    if [[ $? -eq 0 ]]; then
        log "✅ Created pipeline $run_name in $namespace"
        echo "$namespace:$run_name" >> "$LOG_DIR/active-pipelines.txt"
    else
        error "❌ Failed to create pipeline in $namespace"
        cat "$LOG_DIR/${namespace}-wave${wave}.log"
    fi
}

# Function to monitor resources
monitor_resources() {
    log "📊 Starting resource monitoring..."
    
    while true; do
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Node resources
        echo "=== $timestamp ===" >> "$LOG_DIR/node-resources.log"
        oc adm top nodes >> "$LOG_DIR/node-resources.log" 2>/dev/null || echo "Failed to get node resources" >> "$LOG_DIR/node-resources.log"
        echo "" >> "$LOG_DIR/node-resources.log"
        
        # Pod counts and status
        echo "=== $timestamp ===" >> "$LOG_DIR/pod-status.log"
        oc get pods -A -l app.kubernetes.io/managed-by=tekton-pipelines --no-headers | \
        awk '{print $4}' | sort | uniq -c >> "$LOG_DIR/pod-status.log"
        echo "" >> "$LOG_DIR/pod-status.log"
        
        # Pipeline summary
        echo "=== $timestamp ===" >> "$LOG_DIR/pipeline-summary.log"
        {
            echo "Running: $(oc get pipelineruns -A --no-headers | grep Running | wc -l)"
            echo "Succeeded: $(oc get pipelineruns -A --no-headers | grep Succeeded | wc -l)" 
            echo "Failed: $(oc get pipelineruns -A --no-headers | grep Failed | wc -l)"
        } >> "$LOG_DIR/pipeline-summary.log"
        echo "" >> "$LOG_DIR/pipeline-summary.log"
        
        sleep 30
    done
}

# Start monitoring in background if requested
if [[ $MONITOR == true ]]; then
    monitor_resources &
    MONITOR_PID=$!
    log "📊 Started resource monitoring (PID: $MONITOR_PID)"
fi

# Execute load test in waves
STUDENTS_PER_WAVE=$((STUDENT_COUNT / WAVES))
STUDENT_ARRAY=($AVAILABLE_STUDENTS)

for wave in $(seq 1 $WAVES); do
    log "🌊 Starting Wave $wave/$WAVES"
    
    start_idx=$(((wave - 1) * STUDENTS_PER_WAVE))
    end_idx=$((wave * STUDENTS_PER_WAVE))
    
    # Handle remainder in last wave
    if [[ $wave -eq $WAVES ]]; then
        end_idx=$STUDENT_COUNT
    fi
    
    # Create pipelines for this wave
    for i in $(seq $start_idx $((end_idx - 1))); do
        namespace=${STUDENT_ARRAY[$i]}
        create_pipeline_run "$namespace" "$wave" &
    done
    
    # Wait for all pipeline creations in this wave
    wait
    log "✅ Wave $wave completed - pipelines created"
    
    # Delay before next wave
    if [[ $wave -lt $WAVES && $DELAY -gt 0 ]]; then
        log "⏱️ Waiting ${DELAY}s before next wave..."
        sleep "$DELAY"
    fi
done

log "🚀 All pipeline runs created!"

# Monitor pipeline execution
ACTIVE_PIPELINES=$(wc -l < "$LOG_DIR/active-pipelines.txt" 2>/dev/null || echo "0")
log "⏳ Waiting for $ACTIVE_PIPELINES pipelines to complete..."

# Wait for completion and collect results
start_time=$(date +%s)
while true; do
    RUNNING=$(oc get pipelineruns -A --no-headers | grep Running | wc -l || echo "0")
    SUCCEEDED=$(oc get pipelineruns -A --no-headers | grep Succeeded | wc -l || echo "0") 
    FAILED=$(oc get pipelineruns -A --no-headers | grep Failed | wc -l || echo "0")
    
    elapsed=$(($(date +%s) - start_time))
    log "Status (${elapsed}s): Running=$RUNNING, Succeeded=$SUCCEEDED, Failed=$FAILED"
    
    if [[ $RUNNING -eq 0 ]]; then
        log "🎉 All pipelines completed!"
        break
    fi
    
    sleep 30
done

# Stop monitoring
if [[ $MONITOR == true && -n $MONITOR_PID ]]; then
    kill $MONITOR_PID 2>/dev/null || true
    log "📊 Stopped resource monitoring"
fi

# Generate final report
end_time=$(date +%s)
total_time=$((end_time - start_time))

log "📋 Generating test report..."

cat > "$LOG_DIR/load-test-report.md" << EOF
# Pipeline Load Test Report

**Test Configuration:**
- Students: $STUDENT_COUNT
- Waves: $WAVES
- Delay: ${DELAY}s
- Monitor: $MONITOR
- Total Duration: ${total_time}s ($(($total_time / 60))m $(($total_time % 60))s)
- Timestamp: $(date)

**Results:**
- Succeeded: $SUCCEEDED
- Failed: $FAILED
- Success Rate: $(( SUCCEEDED * 100 / (SUCCEEDED + FAILED) ))%

**Cluster Information:**
- Worker Nodes: $(oc get nodes --no-headers | grep worker | wc -l)
- Total Cores: $(oc get nodes --no-headers | grep worker | wc -l | awk '{print $1 * 4}')

**Performance:**
- Average Pipeline Duration: ~$(($total_time / STUDENT_COUNT))s per pipeline
- Concurrent Execution: $(($STUDENT_COUNT > 1 ? "YES" : "NO"))

EOF

if [[ $MONITOR == true ]]; then
    echo "**Resource Monitoring Files:**" >> "$LOG_DIR/load-test-report.md"
    echo "- node-resources.log" >> "$LOG_DIR/load-test-report.md"
    echo "- pod-status.log" >> "$LOG_DIR/load-test-report.md"
    echo "- pipeline-summary.log" >> "$LOG_DIR/load-test-report.md"
fi

# Cleanup if requested
if [[ $CLEANUP == true ]]; then
    log "🧹 Cleaning up test pipelines..."
    oc get pipelineruns -A --no-headers | grep loadtest | while read namespace name status age; do
        oc delete pipelinerun "$name" -n "$namespace" &
    done
    wait
    log "✅ Cleanup completed"
fi

log "✅ Load test completed!"
log "📋 Report available at: $LOG_DIR/load-test-report.md"
log "📊 Detailed logs in: $LOG_DIR/"

if [[ $FAILED -gt 0 ]]; then
    warn "⚠️  $FAILED pipelines failed - check logs for details"
    exit 1
fi
