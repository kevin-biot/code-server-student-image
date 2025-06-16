#!/bin/bash
# monitor-students.sh - Monitor student environments

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if we're logged into OpenShift
if ! oc whoami &> /dev/null; then
    error "Not logged into OpenShift. Please run 'oc login' first."
    exit 1
fi

echo "=== Student Environment Status ==="
echo

# Get all student namespaces
student_namespaces=$(oc get namespaces -l student --no-headers -o custom-columns=":metadata.name" 2>/dev/null)

if [[ -z "$student_namespaces" ]]; then
    warn "No student namespaces found"
    exit 0
fi

echo "Found $(echo "$student_namespaces" | wc -l) student environments:"
echo

# Table header
printf "%-12s %-10s %-8s %-15s %-15s %-50s\n" "STUDENT" "STATUS" "READY" "CPU" "MEMORY" "URL"
printf "%-12s %-10s %-8s %-15s %-15s %-50s\n" "--------" "------" "-----" "---" "------" "---"

for ns in $student_namespaces; do
    # Get deployment status
    deployment_status=$(oc get deployment code-server -n "$ns" --no-headers -o custom-columns=":status.conditions[?(@.type=='Available')].status" 2>/dev/null || echo "Unknown")
    ready_replicas=$(oc get deployment code-server -n "$ns" --no-headers -o custom-columns=":status.readyReplicas" 2>/dev/null || echo "0")
    desired_replicas=$(oc get deployment code-server -n "$ns" --no-headers -o custom-columns=":spec.replicas" 2>/dev/null || echo "1")
    
    # Get resource usage
    cpu_usage=$(oc top pod -n "$ns" --no-headers 2>/dev/null | awk '{print $2}' || echo "N/A")
    memory_usage=$(oc top pod -n "$ns" --no-headers 2>/dev/null | awk '{print $3}' || echo "N/A")
    
    # Get route URL
    route_url=$(oc get route code-server -n "$ns" -o jsonpath='{.spec.host}' 2>/dev/null || echo "N/A")
    
    # Format status
    if [[ "$deployment_status" == "True" ]]; then
        status_color="${GREEN}Running${NC}"
    else
        status_color="${RED}Failed${NC}"
    fi
    
    # Format ready status
    ready_status="${ready_replicas}/${desired_replicas}"
    
    printf "%-12s %-18s %-8s %-15s %-15s %-50s\n" \
        "$ns" \
        "$status_color" \
        "$ready_status" \
        "${cpu_usage:-N/A}" \
        "${memory_usage:-N/A}" \
        "https://$route_url"
done

echo
echo "=== Resource Usage Summary ==="

# Get resource quotas
log "Resource quotas per namespace:"
oc get resourcequota -A | grep student | while read line; do
    namespace=$(echo "$line" | awk '{print $1}')
    used_cpu=$(echo "$line" | awk '{print $4}' | cut -d'/' -f1)
    limit_cpu=$(echo "$line" | awk '{print $4}' | cut -d'/' -f2)
    used_memory=$(echo "$line" | awk '{print $5}' | cut -d'/' -f1)
    limit_memory=$(echo "$line" | awk '{print $5}' | cut -d'/' -f2)
    
    echo "  $namespace: CPU ${used_cpu}/${limit_cpu}, Memory ${used_memory}/${limit_memory}"
done

echo
echo "=== Recent Events ==="

# Show recent events for student namespaces
for ns in $(echo "$student_namespaces" | head -5); do
    echo "Recent events for $ns:"
    oc get events -n "$ns" --sort-by='.lastTimestamp' | tail -3 | sed 's/^/  /'
done

echo
info "Monitoring complete. Run 'oc get pods -A | grep code-server' for detailed pod status."
