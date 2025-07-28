#!/bin/bash
# ==================================================================
# PVC Preflight Health Check - Daily Ghost Node Monitoring
# Reports PVC issues without fixing them - for logging and metrics
# FIXED: Compatible with older bash versions
# ==================================================================

set -euo pipefail

echo "👻 PVC PREFLIGHT HEALTH CHECK - Ghost Node Detection"
echo "===================================================="
echo "📅 Check performed: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "🖥️  Cluster: $(oc whoami --show-server 2>/dev/null || echo 'Unknown')"
echo "👤 User: $(oc whoami 2>/dev/null || echo 'Unknown')"
echo

# Configuration
STUDENT_RANGE_START=${1:-1}
STUDENT_RANGE_END=${2:-37}
OUTPUT_FORMAT=${3:-"table"}  # table, json, csv
LOG_FILE="/tmp/pvc-preflight-$(date +%Y%m%d-%H%M%S).log"

echo "⚙️  Configuration:"
echo "   • Student range: $(printf "student%02d" $STUDENT_RANGE_START) to $(printf "student%02d" $STUDENT_RANGE_END)"
echo "   • Output format: $OUTPUT_FORMAT"
echo "   • Log file: $LOG_FILE"
echo "   • Mode: READ-ONLY (no fixes applied)"
echo

# Validate permissions (read-only checks)
echo "🔍 Validating read permissions..."
if ! oc auth can-i get pvc --all-namespaces >/dev/null 2>&1; then
    echo "❌ ERROR: Insufficient permissions to read PVCs across namespaces."
    echo "   This script requires read access to PVCs and nodes."
    exit 1
fi

echo "✅ Read permissions confirmed"
echo

# Initialize counters (compatible with older bash)
total_namespaces=0
total_pvcs=0
bound_pvcs=0
pending_pvcs=0
ghost_node_pvcs=0
healthy_pvcs=0
missing_pvcs=0
unknown_status_pvcs=0

declare -a GHOST_NODE_FINDINGS=()
declare -a HEALTHY_FINDINGS=()
declare -a ISSUE_FINDINGS=()

# Function to get PVC details
get_pvc_details() {
    local namespace=$1
    local pvc_name=$2
    
    # Get PVC info
    local pvc_info=$(oc get pvc "$pvc_name" -n "$namespace" --no-headers 2>/dev/null || echo "NOTFOUND")
    
    if [[ "$pvc_info" == "NOTFOUND" ]]; then
        echo "MISSING|||||||"
        return
    fi
    
    local status=$(echo "$pvc_info" | awk '{print $2}')
    local volume=$(echo "$pvc_info" | awk '{print $3}')
    local capacity=$(echo "$pvc_info" | awk '{print $4}')
    local access_mode=$(echo "$pvc_info" | awk '{print $5}')
    local storage_class=$(echo "$pvc_info" | awk '{print $6}')
    local age=$(echo "$pvc_info" | awk '{print $7}')
    
    # Get selected node if bound
    local selected_node=""
    if [[ "$status" == "Bound" ]]; then
        selected_node=$(oc get pvc "$pvc_name" -n "$namespace" -o jsonpath='{.metadata.annotations.volume\.kubernetes\.io/selected-node}' 2>/dev/null || echo "")
    fi
    
    echo "$status|$volume|$capacity|$access_mode|$storage_class|$age|$selected_node"
}

# Function to check if node exists
node_exists() {
    local node_name=$1
    [[ -n "$node_name" ]] && oc get node "$node_name" >/dev/null 2>&1
}

# Function to analyze PVC health
analyze_pvc_health() {
    local namespace=$1
    local pvc_name=$2
    local pvc_details=$3
    
    IFS='|' read -r status volume capacity access_mode storage_class age selected_node <<< "$pvc_details"
    
    case "$status" in
        "MISSING")
            missing_pvcs=$((missing_pvcs + 1))
            ISSUE_FINDINGS+=("$namespace|$pvc_name|MISSING|No PVC found in namespace||")
            ;;
        "Bound")
            bound_pvcs=$((bound_pvcs + 1))
            if [[ -n "$selected_node" ]]; then
                if node_exists "$selected_node"; then
                    healthy_pvcs=$((healthy_pvcs + 1))
                    HEALTHY_FINDINGS+=("$namespace|$pvc_name|HEALTHY|Bound to existing node|$selected_node|$age")
                else
                    ghost_node_pvcs=$((ghost_node_pvcs + 1))
                    GHOST_NODE_FINDINGS+=("$namespace|$pvc_name|GHOST_NODE|Bound to missing node|$selected_node|$age")
                fi
            else
                healthy_pvcs=$((healthy_pvcs + 1))
                HEALTHY_FINDINGS+=("$namespace|$pvc_name|BOUND_NO_NODE|Bound but no node annotation||$age")
            fi
            ;;
        "Pending")
            pending_pvcs=$((pending_pvcs + 1))
            HEALTHY_FINDINGS+=("$namespace|$pvc_name|PENDING|Normal - waiting for pod|$selected_node|$age")
            ;;
        *)
            unknown_status_pvcs=$((unknown_status_pvcs + 1))
            ISSUE_FINDINGS+=("$namespace|$pvc_name|UNKNOWN|Status: $status|$selected_node|$age")
            ;;
    esac
    
    total_pvcs=$((total_pvcs + 1))
}

# Main scanning loop
echo "🔍 Scanning student namespaces for PVC health..."
echo

# Check each student namespace
for i in $(seq $STUDENT_RANGE_START $STUDENT_RANGE_END); do
    namespace="student$(printf "%02d" $i)"
    
    # Check if namespace exists
    if ! oc get namespace "$namespace" >/dev/null 2>&1; then
        echo "   ⚠️  $namespace: Namespace not found"
        continue
    fi
    
    STATS[total_namespaces]=$((STATS[total_namespaces] + 1))
    echo -n "   🔍 $namespace: "
    
    # Check for common PVC names
    pvc_names=("shared-pvc" "code-server-pvc" "pipeline-workspace")
    found_pvcs=0
    
    for pvc_name in "${pvc_names[@]}"; do
        pvc_details=$(get_pvc_details "$namespace" "$pvc_name")
        
        if [[ "$pvc_details" != "MISSING|||||||" ]]; then
            analyze_pvc_health "$namespace" "$pvc_name" "$pvc_details"
            ((found_pvcs++))
        fi
    done
    
    if [[ $found_pvcs -eq 0 ]]; then
        echo "No standard PVCs found"
    else
        echo "$found_pvcs PVCs analyzed"
    fi
done

echo
echo "📊 ANALYSIS COMPLETE"
echo "==================="

# Generate summary statistics
echo "📈 Summary Statistics:"
echo "   • Namespaces scanned: ${STATS[total_namespaces]}"
echo "   • Total PVCs found: ${STATS[total_pvcs]}"
echo "   • Healthy PVCs: ${STATS[healthy_pvcs]}"
echo "   • Pending PVCs: ${STATS[pending_pvcs]} (normal)"
echo "   • 👻 Ghost node PVCs: ${STATS[ghost_node_pvcs]}"
echo "   • Missing PVCs: ${STATS[missing_pvcs]}"
echo "   • Unknown status PVCs: ${STATS[unknown_status_pvcs]}"
echo

# Calculate health percentage
if [[ ${STATS[total_pvcs]} -gt 0 ]]; then
    health_percentage=$(( (STATS[healthy_pvcs] + STATS[pending_pvcs]) * 100 / STATS[total_pvcs] ))
    echo "🎯 Overall PVC Health: $health_percentage%"
else
    echo "🎯 Overall PVC Health: N/A (no PVCs found)"
fi

# Ghost node alerts
if [[ ${STATS[ghost_node_pvcs]} -gt 0 ]]; then
    echo
    echo "🚨 GHOST NODE ALERT: ${STATS[ghost_node_pvcs]} PVCs bound to missing nodes!"
    echo "   This will cause 'volume node affinity conflict' errors"
    echo "   Run enhanced restart script to fix these issues"
    echo
fi

# Detailed findings based on output format
case "$OUTPUT_FORMAT" in
    "table")
        if [[ ${#GHOST_NODE_FINDINGS[@]} -gt 0 ]]; then
            echo "👻 GHOST NODE FINDINGS:"
            echo "======================"
            printf "%-12s %-20s %-12s %-30s %-30s %-8s\n" "NAMESPACE" "PVC" "STATUS" "ISSUE" "MISSING_NODE" "AGE"
            printf "%-12s %-20s %-12s %-30s %-30s %-8s\n" "--------" "---" "------" "-----" "------------" "---"
            for finding in "${GHOST_NODE_FINDINGS[@]}"; do
                IFS='|' read -r ns pvc status issue node age <<< "$finding"
                printf "%-12s %-20s %-12s %-30s %-30s %-8s\n" "$ns" "$pvc" "$status" "$issue" "$node" "$age"
            done
            echo
        fi
        
        if [[ ${#ISSUE_FINDINGS[@]} -gt 0 ]]; then
            echo "⚠️  OTHER ISSUES:"
            echo "================"
            printf "%-12s %-20s %-12s %-30s %-30s %-8s\n" "NAMESPACE" "PVC" "STATUS" "ISSUE" "NODE" "AGE"
            printf "%-12s %-20s %-12s %-30s %-30s %-8s\n" "--------" "---" "------" "-----" "----" "---"
            for finding in "${ISSUE_FINDINGS[@]}"; do
                IFS='|' read -r ns pvc status issue node age <<< "$finding"
                printf "%-12s %-20s %-12s %-30s %-30s %-8s\n" "$ns" "$pvc" "$status" "$issue" "$node" "$age"
            done
            echo
        fi
        ;;
        
    "json")
        cat > "$LOG_FILE" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "cluster": "$(oc whoami --show-server 2>/dev/null || echo 'Unknown')",
  "statistics": {
    "total_namespaces": ${STATS[total_namespaces]},
    "total_pvcs": ${STATS[total_pvcs]},
    "healthy_pvcs": ${STATS[healthy_pvcs]},
    "pending_pvcs": ${STATS[pending_pvcs]},
    "ghost_node_pvcs": ${STATS[ghost_node_pvcs]},
    "missing_pvcs": ${STATS[missing_pvcs]},
    "unknown_status_pvcs": ${STATS[unknown_status_pvcs]},
    "health_percentage": $(( ${STATS[total_pvcs]} > 0 ? (STATS[healthy_pvcs] + STATS[pending_pvcs]) * 100 / STATS[total_pvcs] : 0 ))
  }
}
EOF
        echo "📄 JSON report saved to: $LOG_FILE"
        ;;
        
    "csv")
        cat > "$LOG_FILE" << EOF
timestamp,cluster,namespace,pvc,status,issue,node,age,finding_type
EOF
        for finding in "${GHOST_NODE_FINDINGS[@]}"; do
            IFS='|' read -r ns pvc status issue node age <<< "$finding"
            echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),$(oc whoami --show-server 2>/dev/null || echo 'Unknown'),$ns,$pvc,$status,$issue,$node,$age,ghost_node" >> "$LOG_FILE"
        done
        
        for finding in "${ISSUE_FINDINGS[@]}"; do
            IFS='|' read -r ns pvc status issue node age <<< "$finding"
            echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),$(oc whoami --show-server 2>/dev/null || echo 'Unknown'),$ns,$pvc,$status,$issue,$node,$age,other_issue" >> "$LOG_FILE"
        done
        
        echo "📄 CSV report saved to: $LOG_FILE"
        ;;
esac

# Recommendations
echo "💡 RECOMMENDATIONS:"
echo "==================="

if [[ ${STATS[ghost_node_pvcs]} -gt 0 ]]; then
    echo "🚨 CRITICAL: ${STATS[ghost_node_pvcs]} ghost node PVCs detected!"
    echo "   • Run enhanced restart script to fix: ./restart-codeserver.sh"
    echo "   • Or clean manually: oc delete pvc shared-pvc -n [namespace]"
    echo
fi

if [[ ${STATS[missing_pvcs]} -gt 0 ]]; then
    echo "⚠️  ${STATS[missing_pvcs]} missing PVCs detected!"
    echo "   • Check if student environments are properly deployed"
    echo "   • May need to re-run student template deployment"
    echo
fi

if [[ ${STATS[ghost_node_pvcs]} -eq 0 && ${STATS[missing_pvcs]} -eq 0 && ${STATS[unknown_status_pvcs]} -eq 0 ]]; then
    echo "✅ No critical issues found - PVC health is good!"
    echo "   • All PVCs are either healthy or properly pending"
    echo "   • No ghost node bindings detected"
    echo
fi

# Monitoring suggestions
echo "📊 MONITORING SUGGESTIONS:"
echo "========================="
echo "   • Run daily: $0 > /var/log/pvc-health-\$(date +%Y%m%d).log"
echo "   • Set alert if ghost_node_pvcs > 0"
echo "   • Track health_percentage trend over time"
echo "   • Monitor after AWS auto-scaling events"
echo

# Exit codes for automation
if [[ ${STATS[ghost_node_pvcs]} -gt 0 ]]; then
    echo "❌ Exiting with code 1 (ghost nodes detected)"
    exit 1
elif [[ ${STATS[missing_pvcs]} -gt 0 || ${STATS[unknown_status_pvcs]} -gt 0 ]]; then
    echo "⚠️  Exiting with code 2 (other issues detected)"
    exit 2
else
    echo "✅ Exiting with code 0 (healthy)"
    exit 0
fi
