#!/bin/bash
# Batch pod deletion and testing script

echo "🔥 BATCH POD DELETION AND TESTING"

# Function to delete pods in batches
delete_pods_batch() {
    local batch_size=${1:-5}
    local student_count=${2:-37}
    
    echo "🗑️ Deleting code-server pods in batches of $batch_size..."
    
    for ((i=1; i<=student_count; i+=batch_size)); do
        echo "📦 Batch $(((i-1)/batch_size + 1)): Students $i to $((i+batch_size-1))"
        
        for ((j=i; j<i+batch_size && j<=student_count; j++)); do
            local student_ns=$(printf "student%02d" $j)
            echo "  🗑️ Deleting pod in $student_ns..."
            oc delete pods -l app=code-server -n $student_ns 2>/dev/null || echo "    ⚠️ No pods or namespace not found"
        done
        
        echo "  ⏳ Waiting 10 seconds for pods to restart..."
        sleep 10
        
        # Check if pods are running
        echo "  ✅ Checking pod status..."
        for ((j=i; j<i+batch_size && j<=student_count; j++)); do
            local student_ns=$(printf "student%02d" $j)
            local pod_status=$(oc get pods -n $student_ns -l app=code-server --no-headers 2>/dev/null | awk '{print $3}')
            if [[ "$pod_status" == "Running" ]]; then
                echo "    ✅ $student_ns: Pod running"
            else
                echo "    ⏳ $student_ns: Pod status: ${pod_status:-NOT_FOUND}"
            fi
        done
        
        echo ""
    done
}

# Function to run final test
run_final_test() {
    echo "🧪 RUNNING FINAL VALIDATION TEST"
    echo "Expected: 100% pass rate after fixes"
    echo ""
    
    ./codeserver_test_framework.sh auto
    
    echo ""
    echo "🎯 TARGET: 518/518 tests passed (100%)"
}

# Main execution
case "${1:-}" in
    "delete")
        batch_size=${2:-5}
        delete_pods_batch $batch_size 37
        ;;
    "test")
        run_final_test
        ;;
    "all")
        batch_size=${2:-5}
        delete_pods_batch $batch_size 37
        echo "⏳ Waiting 30 seconds for all pods to fully restart..."
        sleep 30
        run_final_test
        ;;
    *)
        echo "Usage: $0 [delete [batch_size]|test|all [batch_size]]"
        echo ""
        echo "Examples:"
        echo "  $0 delete 5     # Delete pods in batches of 5"
        echo "  $0 test         # Run validation test only"
        echo "  $0 all 3        # Delete in batches of 3, then test"
        echo ""
        echo "Default batch size: 5 students at a time"
        ;;
esac
