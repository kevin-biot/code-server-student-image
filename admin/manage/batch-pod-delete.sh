#!/bin/bash
# Batch Pod Deletion Script - 3 at a time with 4 minute intervals

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Batch Pod Deletion Script${NC}"
echo -e "${BLUE}Deleting 3 pods at a time, 4 minute intervals${NC}"
echo ""

# Function to delete a batch of 3 pods
delete_batch() {
    local batch_num=$1
    shift
    local students=("$@")
    
    echo -e "${YELLOW}=== Batch $batch_num: Deleting 3 pods ===${NC}"
    
    for student in "${students[@]}"; do
        echo -e "${BLUE}🗑️ Deleting pod in $student...${NC}"
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
    
    # Check node distribution
    echo "Node distribution:"
    oc get pods -o wide --all-namespaces | grep code-server | awk '{print $8}' | sort | uniq -c
    echo ""
    
    # Check pending pods
    echo "Pending pods:"
    pending_count=$(oc get pods --all-namespaces | grep Pending | wc -l)
    if [ "$pending_count" -eq 0 ]; then
        echo -e "${GREEN}✅ No pending pods${NC}"
    else
        echo -e "${YELLOW}⚠️ $pending_count pending pods found${NC}"
        oc get pods --all-namespaces | grep Pending
    fi
    echo ""
}

# Function to test a student after replacement
test_student() {
    local student=$1
    echo -e "${BLUE}🧪 Testing $student (should have new image):${NC}"
    ./codeserver_test_framework.sh single ${student#student}
    echo ""
}

# Define batches based on the heavy node pods we found
# Targeting oldest pods first (39-40h old)
BATCH1=("student20" "student22" "student24")
BATCH2=("student26" "student29" "student09")  
BATCH3=("student06" "student12")  # These are 17h old, newer but still pre-fixes

echo -e "${YELLOW}🎯 Target: Replace old pods with fresh images containing README fixes${NC}"
echo "Heavy node (ip-10-0-42-7) currently has 9 pods"
echo "Plan: 3 batches of 3 pods each, 4 minute intervals"
echo ""

# Batch 1: Oldest pods (39h)
delete_batch 1 "${BATCH1[@]}"
echo -e "${YELLOW}⏳ Waiting 4 minutes for pods to reschedule...${NC}"
sleep 240
check_status 1
test_student "student20"

echo -e "${BLUE}Press Enter to continue to Batch 2, or Ctrl+C to stop...${NC}"
read -r

# Batch 2: More old pods (39-40h)
delete_batch 2 "${BATCH2[@]}"
echo -e "${YELLOW}⏳ Waiting 4 minutes for pods to reschedule...${NC}"
sleep 240
check_status 2  
test_student "student26"

echo -e "${BLUE}Press Enter to continue to Batch 3, or Ctrl+C to stop...${NC}"
read -r

# Batch 3: Medium age pods (17h)
delete_batch 3 "${BATCH3[@]}"
echo -e "${YELLOW}⏳ Waiting 4 minutes for pods to reschedule...${NC}"
sleep 240
check_status 3
test_student "student06"

echo -e "${GREEN}🎉 All batches complete!${NC}"
echo ""
echo -e "${BLUE}📊 Final Summary:${NC}"
echo "Final node distribution:"
oc get pods -o wide --all-namespaces | grep code-server | awk '{print $8}' | sort | uniq -c
echo ""
echo "Final pending pods check:"
oc get pods --all-namespaces | grep Pending | wc -l | xargs echo "Pending pods:"

echo ""
echo -e "${GREEN}✅ Batch deletion complete! Heavy node should now have better distribution.${NC}"
echo -e "${BLUE}🧪 Run full test suite: ./codeserver_test_framework.sh auto${NC}"
