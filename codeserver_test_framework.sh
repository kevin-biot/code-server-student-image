#!/bin/bash

# Code Server File Validation Test Framework
# Author: Infrastructure Team
# Purpose: Validate that all required files exist in correct locations across all code server instances

# Configuration
NAMESPACE_PREFIX="student"
DEPLOYMENT_NAME="code-server"
BASE_PATH="/home/coder/workspace"
EXPECTED_GIT_CLONE_URL="https://github.com/kevin-biot/IaC"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test Results Tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0
EXPECTED_STUDENT_COUNT=0
ACTUAL_STUDENT_COUNT=0

# Log file with timestamp
LOG_FILE="codeserver_validation_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to print colored output
print_status() {
    local status=$1
    local student=$2
    local message=$3
    
    case $status in
        "PASS")
            echo -e "${GREEN}✅ $student: $message${NC}"
            ((PASSED_TESTS++))
            ;;
        "FAIL")
            echo -e "${RED}❌ $student: $message${NC}"
            ((FAILED_TESTS++))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  $student: $message${NC}"
            ((WARNINGS++))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $student: $message${NC}"
            ;;
        "CRITICAL")
            echo -e "${RED}🚨 CRITICAL: $student: $message${NC}"
            ;;
    esac
    
    log_message "$status" "$student: $message"
}

# Function to detect existing student namespaces
detect_student_namespaces() {
    local namespaces=$(oc get namespaces -o name 2>/dev/null | grep "namespace/$NAMESPACE_PREFIX" | sed "s/namespace\///g" | sort)
    echo "$namespaces"
}

# Function to extract student numbers from namespace names
extract_student_numbers() {
    local namespaces="$1"
    local numbers=()
    
    while IFS= read -r namespace; do
        if [[ "$namespace" =~ ^${NAMESPACE_PREFIX}([0-9]+)$ ]]; then
            numbers+=(${BASH_REMATCH[1]})
        fi
    done <<< "$namespaces"
    
    # Sort numbers numerically
    printf '%s\n' "${numbers[@]}" | sort -n
}

# Function to validate namespace count and get expected count
validate_and_get_student_count() {
    local mode=$1  # "auto", "prompt", or specific number
    
    echo -e "${CYAN}=== Student Namespace Detection ===${NC}"
    
    # Detect existing namespaces
    local detected_namespaces=$(detect_student_namespaces)
    ACTUAL_STUDENT_COUNT=$(echo "$detected_namespaces" | wc -l)
    
    if [[ -z "$detected_namespaces" ]]; then
        echo -e "${RED}❌ No student namespaces found!${NC}"
        echo "Expected namespace pattern: ${NAMESPACE_PREFIX}NN (e.g., student01, student15)"
        log_message "CRITICAL" "No student namespaces detected"
        exit 1
    fi
    
    echo -e "${BLUE}Detected student namespaces:${NC}"
    echo "$detected_namespaces" | while IFS= read -r ns; do
        echo "  - $ns"
    done
    echo ""
    
    local student_numbers=$(extract_student_numbers "$detected_namespaces")
    echo -e "${BLUE}Student numbers found:${NC} $(echo $student_numbers | tr '\n' ' ')"
    echo -e "${BLUE}Total detected:${NC} $ACTUAL_STUDENT_COUNT"
    echo ""
    
    # Determine expected count based on mode
    case "$mode" in
        "auto")
            EXPECTED_STUDENT_COUNT=$ACTUAL_STUDENT_COUNT
            echo -e "${GREEN}✅ Auto-detection mode: Testing all $ACTUAL_STUDENT_COUNT detected students${NC}"
            ;;
        "prompt")
            echo -e "${YELLOW}Current detected count: $ACTUAL_STUDENT_COUNT${NC}"
            while true; do
                echo -n "Enter expected number of students (or 'auto' to use detected count): "
                read -r input
                
                if [[ "$input" == "auto" ]]; then
                    EXPECTED_STUDENT_COUNT=$ACTUAL_STUDENT_COUNT
                    break
                elif [[ "$input" =~ ^[0-9]+$ ]] && [[ "$input" -gt 0 ]]; then
                    EXPECTED_STUDENT_COUNT=$input
                    break
                else
                    echo -e "${RED}Please enter a valid positive number or 'auto'${NC}"
                fi
            done
            ;;
        *)
            # Specific number provided
            if [[ "$mode" =~ ^[0-9]+$ ]] && [[ "$mode" -gt 0 ]]; then
                EXPECTED_STUDENT_COUNT=$mode
            else
                echo -e "${RED}Invalid student count: $mode${NC}"
                exit 1
            fi
            ;;
    esac
    
    # Validate count consistency
    if [[ $EXPECTED_STUDENT_COUNT -ne $ACTUAL_STUDENT_COUNT ]]; then
        echo -e "${RED}🚨 COUNT MISMATCH DETECTED!${NC}"
        echo -e "${RED}Expected: $EXPECTED_STUDENT_COUNT students${NC}"
        echo -e "${RED}Detected: $ACTUAL_STUDENT_COUNT students${NC}"
        echo ""
        echo -e "${YELLOW}Possible issues:${NC}"
        echo "  - Some namespaces not created yet"
        echo "  - Some namespaces deleted/missing"
        echo "  - Naming convention not followed"
        echo "  - Infrastructure deployment incomplete"
        echo ""
        echo -e "${YELLOW}Recommended actions:${NC}"
        echo "  1. Check deployment status"
        echo "  2. Verify namespace creation process"
        echo "  3. Re-run deployment if needed"
        echo "  4. Run test again after resolution"
        echo ""
        log_message "CRITICAL" "Count mismatch - Expected: $EXPECTED_STUDENT_COUNT, Actual: $ACTUAL_STUDENT_COUNT"
        
        # Ask if user wants to continue with detected count
        while true; do
            echo -n "Continue with detected count ($ACTUAL_STUDENT_COUNT)? [y/N]: "
            read -r response
            case "$response" in
                [yY]|[yY][eE][sS])
                    EXPECTED_STUDENT_COUNT=$ACTUAL_STUDENT_COUNT
                    echo -e "${YELLOW}⚠️  Continuing with detected count${NC}"
                    break
                    ;;
                [nN]|[nN][oO]|"")
                    echo -e "${RED}Exiting for count resolution${NC}"
                    exit 1
                    ;;
                *)
                    echo "Please answer yes or no."
                    ;;
            esac
        done
    else
        echo -e "${GREEN}✅ Count validation passed: $EXPECTED_STUDENT_COUNT students${NC}"
    fi
    
    echo ""
    return 0
}

# Function to get list of student numbers to test
get_student_numbers_to_test() {
    local detected_namespaces=$(detect_student_namespaces)
    extract_student_numbers "$detected_namespaces"
}

# Function to validate student namespace format
validate_student_namespace() {
    local student_num=$1
    local padded_num=$(printf "%02d" "$student_num")
    local namespace="${NAMESPACE_PREFIX}${padded_num}"
    
    if oc get namespace "$namespace" &>/dev/null; then
        echo "$namespace"
        return 0
    else
        # Try without padding
        local namespace="${NAMESPACE_PREFIX}${student_num}"
        if oc get namespace "$namespace" &>/dev/null; then
            echo "$namespace"
            return 0
        else
            return 1
        fi
    fi
}

# Function to test if code server pod is running
test_pod_running() {
    local student_namespace=$1
    local student_display=$2
    
    local pod_status=$(oc get pod -n "$student_namespace" -l app=code-server --no-headers 2>/dev/null | awk '{print $3}')
    
    if [[ "$pod_status" == "Running" ]]; then
        print_status "PASS" "$student_display" "Pod running"
        return 0
    else
        print_status "FAIL" "$student_display" "Pod not running (Status: ${pod_status:-NOT_FOUND})"
        return 1
    fi
}

# Function to test file existence
test_file_exists() {
    local student_namespace=$1
    local student_display=$2
    local file_path=$3
    local description=$4
    
    ((TOTAL_TESTS++))
    
    if oc exec -n "$student_namespace" "deploy/$DEPLOYMENT_NAME" -- test -f "$file_path" 2>/dev/null; then
        print_status "PASS" "$student_display" "$description exists"
        return 0
    else
        print_status "FAIL" "$student_display" "$description missing: $file_path"
        return 1
    fi
}

# Function to test directory structure
test_directory_structure() {
    local student_namespace=$1
    local student_display=$2
    local dir_path=$3
    local description=$4
    
    ((TOTAL_TESTS++))
    
    if oc exec -n "$student_namespace" "deploy/$DEPLOYMENT_NAME" -- test -d "$dir_path" 2>/dev/null; then
        print_status "PASS" "$student_display" "$description exists"
        return 0
    else
        print_status "FAIL" "$student_display" "$description missing: $dir_path"
        return 1
    fi
}

# Function to test file content
test_file_content() {
    local student_namespace=$1
    local student_display=$2
    local file_path=$3
    local search_pattern=$4
    local description=$5
    
    ((TOTAL_TESTS++))
    
    if oc exec -n "$student_namespace" "deploy/$DEPLOYMENT_NAME" -- grep -q "$search_pattern" "$file_path" 2>/dev/null; then
        print_status "PASS" "$student_display" "$description contains correct content"
        return 0
    else
        print_status "FAIL" "$student_display" "$description missing or incorrect content"
        return 1
    fi
}

# Function to test file permissions
test_file_permissions() {
    local student_namespace=$1
    local student_display=$2
    local file_path=$3
    local expected_perms=$4
    local description=$5
    
    ((TOTAL_TESTS++))
    
    local actual_perms=$(oc exec -n "$student_namespace" "deploy/$DEPLOYMENT_NAME" -- stat -c "%a" "$file_path" 2>/dev/null)
    
    if [[ "$actual_perms" == "$expected_perms" ]]; then
        print_status "PASS" "$student_display" "$description has correct permissions ($expected_perms)"
        return 0
    else
        print_status "WARN" "$student_display" "$description has permissions $actual_perms, expected $expected_perms"
        return 1
    fi
}

# Function to test comprehensive file structure
test_student_environment() {
    local student_num=$1
    local student_namespace
    
    # Determine namespace format
    if ! student_namespace=$(validate_student_namespace "$student_num"); then
        print_status "CRITICAL" "student$student_num" "Namespace not found"
        return 1
    fi
    
    local student_display="$student_namespace"
    
    echo -e "\n${BLUE}=== Testing $student_display Environment ===${NC}"
    
    # Check if pod is running first
    if ! test_pod_running "$student_namespace" "$student_display"; then
        echo -e "${RED}Skipping file tests - pod not running${NC}"
        return 1
    fi
    
    # Test base directory structure
    test_directory_structure "$student_namespace" "$student_display" "$BASE_PATH" "Base workspace directory"
    test_directory_structure "$student_namespace" "$student_display" "$BASE_PATH/labs" "Labs directory"
    test_directory_structure "$student_namespace" "$student_display" "$BASE_PATH/labs/day1-pulumi" "Day 1 Pulumi directory"
    test_directory_structure "$student_namespace" "$student_display" "$BASE_PATH/labs/day2-tekton" "Day 2 Tekton directory"
    test_directory_structure "$student_namespace" "$student_display" "$BASE_PATH/labs/day3-gitops" "Day 3 GitOps directory"
    
    # Test README files existence
    test_file_exists "$student_namespace" "$student_display" "$BASE_PATH/README.md" "Main README"
    test_file_exists "$student_namespace" "$student_display" "$BASE_PATH/labs/README.md" "Labs README"
    test_file_exists "$student_namespace" "$student_display" "$BASE_PATH/labs/day1-pulumi/README.md" "Day 1 README"
    test_file_exists "$student_namespace" "$student_display" "$BASE_PATH/labs/day2-tekton/README.md" "Day 2 README"
    test_file_exists "$student_namespace" "$student_display" "$BASE_PATH/labs/day3-gitops/README.md" "Day 3 README"
    
    # Test README content (if files exist)
    if oc exec -n "$student_namespace" "deploy/$DEPLOYMENT_NAME" -- test -f "$BASE_PATH/labs/day1-pulumi/README.md" 2>/dev/null; then
        test_file_content "$student_namespace" "$student_display" "$BASE_PATH/labs/day1-pulumi/README.md" "$EXPECTED_GIT_CLONE_URL" "Day 1 README"
    fi
    
    # Test for starter files (INFO only - created after git clone)
    if oc exec -n "$student_namespace" "deploy/$DEPLOYMENT_NAME" -- test -f "$BASE_PATH/labs/day1-pulumi/main.py" 2>/dev/null; then
        print_status "INFO" "$student_display" "Day 1 Pulumi main file exists (or created after git clone)"
    else
        print_status "INFO" "$student_display" "Day 1 Pulumi main file will be created during git clone exercise"
    fi
    
    # Test file permissions (example)
    if oc exec -n "$student_namespace" "deploy/$DEPLOYMENT_NAME" -- test -f "$BASE_PATH/README.md" 2>/dev/null; then
        test_file_permissions "$student_namespace" "$student_display" "$BASE_PATH/README.md" "644" "Main README"
    fi
    
    # Test workspace ownership
    local workspace_owner=$(oc exec -n "$student_namespace" "deploy/$DEPLOYMENT_NAME" -- stat -c "%U" "$BASE_PATH" 2>/dev/null)
    if [[ "$workspace_owner" == "coder" ]]; then
        print_status "PASS" "$student_display" "Workspace owned by coder user"
    else
        print_status "WARN" "$student_display" "Workspace owned by $workspace_owner, expected coder"
    fi
    
    ((TOTAL_TESTS++))
    
    echo ""
}

# Function to generate detailed report
generate_report() {
    local report_file="codeserver_test_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
Code Server Environment Validation Report
Generated: $(date)
Expected Students: $EXPECTED_STUDENT_COUNT
Actual Students: $ACTUAL_STUDENT_COUNT
Test Results Summary:
- Total Tests: $TOTAL_TESTS
- Passed: $PASSED_TESTS
- Failed: $FAILED_TESTS
- Warnings: $WARNINGS

Success Rate: $(( TOTAL_TESTS > 0 ? PASSED_TESTS * 100 / TOTAL_TESTS : 0 ))%

Detailed logs available in: $LOG_FILE
EOF
    
    echo -e "\n${BLUE}=== Test Summary ===${NC}"
    echo "Expected Students: $EXPECTED_STUDENT_COUNT"
    echo "Actual Students: $ACTUAL_STUDENT_COUNT"
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        echo "Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
    else
        echo "Success Rate: N/A (no tests executed)"
    fi
    echo ""
    echo "Report saved to: $report_file"
    echo "Detailed logs saved to: $LOG_FILE"
}

# Function to run quick connectivity test
test_connectivity() {
    echo -e "${BLUE}=== Testing OpenShift Connectivity ===${NC}"
    
    if ! oc whoami &>/dev/null; then
        echo -e "${RED}❌ Not logged into OpenShift${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ OpenShift connectivity verified${NC}"
    echo "Current user: $(oc whoami)"
    echo "Current context: $(oc config current-context)"
    echo ""
}

# Function to test specific student (for debugging)
test_single_student() {
    local student_num=$1
    
    echo -e "${BLUE}=== Single Student Test Mode ===${NC}"
    
    # Validate the namespace exists
    if ! validate_student_namespace "$student_num" &>/dev/null; then
        echo -e "${RED}❌ Student $student_num namespace not found${NC}"
        echo "Available students:"
        get_student_numbers_to_test
        exit 1
    fi
    
    EXPECTED_STUDENT_COUNT=1
    ACTUAL_STUDENT_COUNT=1
    
    test_student_environment "$student_num"
    generate_report
}

# Function to show available students
show_available_students() {
    echo -e "${CYAN}=== Available Students ===${NC}"
    local namespaces=$(detect_student_namespaces)
    local numbers=$(extract_student_numbers "$namespaces")
    
    echo "Detected student namespaces:"
    echo "$namespaces" | while IFS= read -r ns; do
        echo "  - $ns"
    done
    
    echo ""
    echo "Student numbers available for testing:"
    echo "$numbers" | tr '\n' ' '
    echo ""
}

# Function to run parallel tests (faster execution)
run_parallel_tests() {
    local student_numbers=$(get_student_numbers_to_test)
    
    echo -e "${BLUE}=== Running Parallel Tests ===${NC}"
    
    # Create temporary directory for parallel job outputs
    local temp_dir=$(mktemp -d)
    
    # Run tests in parallel
    while IFS= read -r student_num; do
        {
            test_student_environment "$student_num"
        } > "$temp_dir/student$student_num.out" 2>&1 &
    done <<< "$student_numbers"
    
    # Wait for all background jobs
    wait
    
    # Collect and display results
    while IFS= read -r student_num; do
        cat "$temp_dir/student$student_num.out"
    done <<< "$student_numbers"
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Main execution
main() {
    echo -e "${BLUE}Code Server File Validation Test Framework${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo ""
    
    # Parse command line arguments
    case "${1:-}" in
        "single")
            if [[ -n "$2" ]]; then
                test_connectivity
                test_single_student "$2"
            else
                echo "Usage: $0 single <student_number>"
                echo ""
                show_available_students
                exit 1
            fi
            ;;
        "parallel")
            test_connectivity
            validate_and_get_student_count "${2:-prompt}"
            run_parallel_tests
            generate_report
            ;;
        "count")
            if [[ -n "$2" ]]; then
                test_connectivity
                validate_and_get_student_count "$2"
                echo -e "${BLUE}Running Sequential Tests...${NC}"
                echo ""
                
                local student_numbers=$(get_student_numbers_to_test)
                while IFS= read -r student_num; do
                    test_student_environment "$student_num"
                done <<< "$student_numbers"
                
                generate_report
            else
                echo "Usage: $0 count <expected_number>"
                exit 1
            fi
            ;;
        "auto")
            test_connectivity
            validate_and_get_student_count "auto"
            echo -e "${BLUE}Running Sequential Tests...${NC}"
            echo ""
            
            local student_numbers=$(get_student_numbers_to_test)
            while IFS= read -r student_num; do
                test_student_environment "$student_num"
            done <<< "$student_numbers"
            
            generate_report
            ;;
        "list")
            test_connectivity
            show_available_students
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [auto|count <N>|parallel [<N>]|single <student_number>|list|help]"
            echo ""
            echo "Options:"
            echo "  auto              Auto-detect student count and run tests"
            echo "  count <N>         Expect N students, validate count, then run tests"
            echo "  parallel [<N>]    Run all tests in parallel (faster), optionally specify expected count"
            echo "  single <N>        Test only student N"
            echo "  list              Show available students"
            echo "  help              Show this help message"
            echo "  (no args)         Interactive mode - prompt for expected count"
            echo ""
            echo "Examples:"
            echo "  $0 auto                    # Auto-detect and test all found students"
            echo "  $0 count 25               # Expect 25 students, validate, then test"
            echo "  $0 parallel 30            # Run parallel tests expecting 30 students"
            echo "  $0 single 15              # Test only student 15"
            echo "  $0 list                   # Show available students"
            exit 0
            ;;
        *)
            test_connectivity
            validate_and_get_student_count "prompt"
            echo -e "${BLUE}Running Sequential Tests...${NC}"
            echo ""
            
            local student_numbers=$(get_student_numbers_to_test)
            while IFS= read -r student_num; do
                test_student_environment "$student_num"
            done <<< "$student_numbers"
            
            generate_report
            ;;
    esac
}

# Run main function with all arguments
main "$@"
