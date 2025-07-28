#!/bin/bash
# teardown-students.sh - Clean removal of student environments

set -e

SCRIPT_NAME="teardown-students.sh"
START_NUM="${1}"
END_NUM="${2}"
CONFIRM="${3:-ask}"

# Function to display usage
usage() {
    echo "Usage: $SCRIPT_NAME <start_number> <end_number> [confirm]"
    echo ""
    echo "Examples:"
    echo "  $SCRIPT_NAME 1 5                    # Remove student01-student05 (with confirmation)"
    echo "  $SCRIPT_NAME 1 25 confirm           # Remove student01-student25 (no confirmation)"
    echo "  $SCRIPT_NAME all all confirm        # Remove ALL student namespaces (no confirmation)"
    echo ""
    echo "Options:"
    echo "  start_number: Starting student number (or 'all')"
    echo "  end_number:   Ending student number (or 'all')"
    echo "  confirm:      'confirm' to skip confirmation prompt"
    exit 1
}

# Check for required parameters
if [ -z "$START_NUM" ] || [ -z "$END_NUM" ]; then
    usage
fi

echo "🧹 Student Environment Teardown"
echo "==============================="

# Handle 'all' option
if [ "$START_NUM" = "all" ] && [ "$END_NUM" = "all" ]; then
    echo "🔍 Finding all student namespaces..."
    STUDENT_NAMESPACES=$(oc get namespaces | grep "^student" | awk '{print $1}' || echo "")
    
    if [ -z "$STUDENT_NAMESPACES" ]; then
        echo "✅ No student namespaces found to remove."
        exit 0
    fi
    
    echo "📋 Found student namespaces:"
    echo "$STUDENT_NAMESPACES" | sed 's/^/   - /'
    TOTAL_COUNT=$(echo "$STUDENT_NAMESPACES" | wc -l)
    
    # Confirmation for 'all'
    if [ "$CONFIRM" != "confirm" ]; then
        echo ""
        echo "⚠️  WARNING: This will delete ALL $TOTAL_COUNT student environments!"
        echo "   This action cannot be undone."
        echo ""
        read -p "Are you sure you want to continue? (type 'DELETE' to confirm): " user_confirm
        if [ "$user_confirm" != "DELETE" ]; then
            echo "❌ Teardown cancelled."
            exit 1
        fi
    fi
    
    # Delete all student namespaces
    echo ""
    echo "🗑️  Deleting all student namespaces..."
    for namespace in $STUDENT_NAMESPACES; do
        echo "   Deleting $namespace..."
        oc delete namespace "$namespace" --ignore-not-found=true > /dev/null &
    done
    
else
    # Handle numbered range
    if ! [[ "$START_NUM" =~ ^[0-9]+$ ]] || ! [[ "$END_NUM" =~ ^[0-9]+$ ]]; then
        echo "❌ Error: Start and end numbers must be integers."
        usage
    fi
    
    if [ "$START_NUM" -gt "$END_NUM" ]; then
        echo "❌ Error: Start number cannot be greater than end number."
        exit 1
    fi
    
    TOTAL_COUNT=$((END_NUM - START_NUM + 1))
    
    echo "📋 Target student environments:"
    for i in $(seq $START_NUM $END_NUM); do
        student_name=$(printf "student%02d" $i)
        if oc get namespace "$student_name" >/dev/null 2>&1; then
            echo "   - $student_name (exists)"
        else
            echo "   - $student_name (not found)"
        fi
    done
    
    # Confirmation for numbered range
    if [ "$CONFIRM" != "confirm" ]; then
        echo ""
        echo "⚠️  WARNING: This will delete $TOTAL_COUNT student environments!"
        echo "   Range: student$(printf "%02d" $START_NUM) to student$(printf "%02d" $END_NUM)"
        echo "   This action cannot be undone."
        echo ""
        read -p "Are you sure you want to continue? (y/N): " user_confirm
        if [[ ! "$user_confirm" =~ ^[Yy]$ ]]; then
            echo "❌ Teardown cancelled."
            exit 1
        fi
    fi
    
    # Delete numbered range
    echo ""
    echo "🗑️  Deleting student environments..."
    for i in $(seq $START_NUM $END_NUM); do
        student_name=$(printf "student%02d" $i)
        echo "   Deleting $student_name..."
        oc delete namespace "$student_name" --ignore-not-found=true > /dev/null &
    done
fi

echo ""
echo "⏳ Namespace deletion initiated (running in background)..."
echo "   This may take 1-2 minutes to complete."

# Wait for deletions to complete
echo ""
echo "🔍 Monitoring deletion progress..."
sleep 5

for attempt in {1..24}; do  # Wait up to 2 minutes
    if [ "$START_NUM" = "all" ]; then
        remaining=$(oc get namespaces | grep "^student" | wc -l || echo 0)
    else
        remaining=0
        for i in $(seq $START_NUM $END_NUM); do
            student_name=$(printf "student%02d" $i)
            if oc get namespace "$student_name" >/dev/null 2>&1; then
                remaining=$((remaining + 1))
            fi
        done
    fi
    
    if [ "$remaining" -eq 0 ]; then
        echo "✅ All student environments successfully deleted!"
        break
    else
        echo "   Remaining: $remaining namespaces (attempt $attempt/24)"
        sleep 5
    fi
done

if [ "$remaining" -gt 0 ]; then
    echo "⚠️  Some namespaces may still be terminating:"
    if [ "$START_NUM" = "all" ]; then
        oc get namespaces | grep "^student" || echo "   None remaining"
    else
        for i in $(seq $START_NUM $END_NUM); do
            student_name=$(printf "student%02d" $i)
            if oc get namespace "$student_name" >/dev/null 2>&1; then
                echo "   - $student_name (still terminating)"
            fi
        done
    fi
    echo "   Check status with: oc get namespaces | grep student"
fi

echo ""
echo "📊 Cleanup Summary:"
echo "   Requested: $TOTAL_COUNT student environments"
echo "   Status: Deletion initiated"
echo ""
echo "💡 To verify complete removal:"
echo "   oc get namespaces | grep student"
echo "   oc get pv | grep student  # Check for orphaned volumes"

# Additional cleanup suggestions
echo ""
echo "🔧 Additional cleanup commands (if needed):"
echo "   # Remove any orphaned PVs:"
echo "   oc get pv | grep student | awk '{print \$1}' | xargs oc delete pv"
echo ""
echo "   # Remove registry RBAC (if cleaning up completely):"
echo "   oc get rolebinding -n devops | grep system:image-puller"
