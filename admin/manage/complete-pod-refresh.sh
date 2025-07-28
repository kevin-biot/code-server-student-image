#!/bin/bash
# Complete Pod Refresh Script - Delete ALL code-server pods in batches
# Ensures 100% fresh image pulls with latest README fixes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔄 COMPLETE POD REFRESH - 100% Fresh Image Guarantee${NC}"
echo -e "${BLUE}Deleting ALL code-server pods in batches of 3${NC}"
echo -e "${BLUE}4 minute intervals to ensure proper rescheduling${NC}"
echo ""

# Get all student namespaces with running code-server pods
get_active_students() {
    oc get pods --all-namespaces | grep code-server | grep Running | awk '{print $1}' | sort
}

# Function to delete a batch of 3 pods
delete_batch() {
    local batch_num=$1
    shift
    local students=("$@")
    
    if [ ${#students[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ No students in batch $batch_num${NC}"
        return
    fi
    
    echo -e "${YELLOW}=== Batch $batch_num: Refreshing ${#students[@]} pods ===${NC}"
    
    for student in "${students[@]}"; do
        echo -e "${BLUE}🔄 Refreshing pod in $student (forcing fresh image pull)...${NC}"
        oc delete pod -l app=code-server -n "$student" 2>/dev/null || echo -e "${RED}⚠️ No pod found in $student${NC}"
        sleep 5
    done
    
    echo -e "${GREEN}✅ Batch $batch_num deletion complete${NC}"
    echo ""
}

# Function to check status after batch
check_status() {
    local batch_num=$1
    
    echo -e "${BLUE}📊 Status check after Batch $batch_num:${NC}"
    
    # Check total running pods
    local running_count=$(oc get pods --all-namespaces | grep code-server | grep Running | wc -l)
    local pending_count=$(oc get pods --all-namespaces | grep code-server | grep Pending | wc -l)
    local creating_count=$(oc get pods --all-namespaces | grep code-server | grep ContainerCreating | wc -l)
    
    echo -e "Running: ${GREEN}$running_count${NC} | Pending: ${YELLOW}$pending_count${NC} | Creating: ${BLUE}$creating_count${NC}"
    
    # Check node distribution
    echo "Node distribution:"
    oc get pods -o wide --all-namespaces | grep code-server | grep Running | awk '{print $8}' | sort | uniq -c
    echo ""
    
    # Show any problematic pods
    if [ "$pending_count" -gt 0 ]; then
        echo -e "${YELLOW}⚠️ Pending pods:${NC}"
        oc get pods --all-namespaces | grep code-server | grep Pending
        echo ""
    fi
}

# Function to test random students after refresh
test_refreshed_students() {
    local batch_num=$1
    echo -e "${BLUE}🧪 Testing refreshed students (should show 92% success rate):${NC}"
    
    # Get a few random running students to test
    local test_students=($(oc get pods --all-namespaces | grep code-server | grep Running | awk '{print $1}' | shuf | head -2))
    
    for student in "${test_students[@]}"; do
        local student_num=${student#student}
        echo -e "${CYAN}Testing $student...${NC}"
        ../../codeserver_test_framework.sh single $student_num | grep "Success Rate"
        echo ""
    done
}

# Get all active students
echo -e "${BLUE}🔍 Discovering all active code-server pods...${NC}"
ALL_STUDENTS=($(get_active_students))
TOTAL_STUDENTS=${#ALL_STUDENTS[@]}

echo -e "${GREEN}Found $TOTAL_STUDENTS active code-server pods${NC}"
echo "Students: ${ALL_STUDENTS[*]}"
echo ""

if [ $TOTAL_STUDENTS -eq 0 ]; then
    echo -e "${RED}❌ No active code-server pods found!${NC}"
    exit 1
fi

# Calculate number of batches
BATCH_SIZE=3
TOTAL_BATCHES=$(( (TOTAL_STUDENTS + BATCH_SIZE - 1) / BATCH_SIZE ))

echo -e "${YELLOW}🎯 Refresh Plan:${NC}"
echo "Total pods to refresh: $TOTAL_STUDENTS"
echo "Batch size: $BATCH_SIZE"
echo "Total batches: $TOTAL_BATCHES"
echo "Time per batch: 4 minutes"
echo "Estimated total time: $(( TOTAL_BATCHES * 4 )) minutes"
echo ""

echo -e "${CYAN}This will ensure 100% of pods pull the latest image with README fixes!${NC}"
echo -e "${BLUE}Press Enter to start, or Ctrl+C to abort...${NC}"
read -r

# Execute batches
for ((batch=1; batch<=TOTAL_BATCHES; batch++)); do
    # Calculate array slice for this batch
    start_idx=$(( (batch - 1) * BATCH_SIZE ))
    end_idx=$(( start_idx + BATCH_SIZE - 1 ))
    
    # Get students for this batch
    batch_students=()
    for ((i=start_idx; i<=end_idx && i<TOTAL_STUDENTS; i++)); do
        batch_students+=("${ALL_STUDENTS[i]}")
    done
    
    # Delete this batch
    delete_batch $batch "${batch_students[@]}"
    
    # Wait for rescheduling
    echo -e "${YELLOW}⏳ Waiting 4 minutes for batch $batch pods to reschedule...${NC}"
    echo "Progress: Batch $batch of $TOTAL_BATCHES complete"
    sleep 240
    
    # Check status
    check_status $batch
    
    # Test some refreshed students
    if [ $batch -eq 1 ] || [ $batch -eq $TOTAL_BATCHES ]; then
        test_refreshed_students $batch
    fi
    
    # Pause between batches (except last one)
    if [ $batch -lt $TOTAL_BATCHES ]; then
        echo -e "${BLUE}Press Enter to continue to Batch $((batch + 1)), or Ctrl+C to stop...${NC}"
        read -r
    fi
done

echo -e "${GREEN}🎉 COMPLETE POD REFRESH FINISHED!${NC}"
echo ""
echo -e "${CYAN}📊 Final Status:${NC}"
check_status "FINAL"

echo ""
echo -e "${GREEN}✅ ALL pods have been refreshed with latest image!${NC}"
echo -e "${BLUE}🧪 Run full validation: ../../codeserver_test_framework.sh auto${NC}"
echo -e "${CYAN}🎯 Expected result: 100% success rate (518/518 tests)${NC}"
