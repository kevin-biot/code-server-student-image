#!/bin/bash
# DOB-74 Validation Test - Core Operational Scripts
# Tests reorganized structure and core functionality

set -e

echo "🧪 DOB-74 Core Operational Scripts Validation"
echo "=============================================="
echo

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success_count=0
total_tests=0

test_result() {
    local test_name="$1"
    local result="$2"
    ((total_tests++))
    
    if [[ "$result" == "PASS" ]]; then
        echo -e "   ✅ ${GREEN}PASS${NC} $test_name"
        ((success_count++))
    else
        echo -e "   ❌ ${RED}FAIL${NC} $test_name"
    fi
}

echo "📋 Testing Reorganized Structure..."

# Test 1: Core admin deployment scripts exist
if [[ -f "admin/deploy/complete-student-setup-simple.sh" && \
      -f "admin/deploy/deploy-bulk-students.sh" && \
      -f "admin/deploy/deploy-students.sh" && \
      -f "admin/deploy/configure-argocd-rbac.sh" ]]; then
    test_result "Admin deployment scripts in place" "PASS"
else
    test_result "Admin deployment scripts in place" "FAIL"
fi

# Test 2: Student template in correct location
if [[ -f "admin/student-template.yaml" ]]; then
    test_result "Student template in admin/ (shared location)" "PASS"
else
    test_result "Student template in admin/ (shared location)" "FAIL"
fi

# Test 3: Management scripts organized
if [[ -f "admin/manage/teardown-students.sh" && \
      -f "admin/manage/monitor-students.sh" && \
      -f "admin/manage/restart-codeserver-enhanced.sh" ]]; then
    test_result "Management scripts organized" "PASS"
else
    test_result "Management scripts organized" "FAIL"
fi

# Test 4: Build script in dev structure
if [[ -f "dev/build/build-and-verify.sh" ]]; then
    test_result "Build script in dev/build/" "PASS"
else
    test_result "Build script in dev/build/" "FAIL"
fi

# Test 5: Test framework in validation
if [[ -f "admin/validate/codeserver_test_framework.sh" ]]; then
    test_result "Test framework in admin/validate/" "PASS"
else
    test_result "Test framework in validation" "FAIL"
fi

# Test 6: Root admin entry point exists
if [[ -f "admin-deploy.sh" && -x "admin-deploy.sh" ]]; then
    test_result "Root admin entry point exists and executable" "PASS"
else
    test_result "Root admin entry point exists and executable" "FAIL"
fi

# Test 7: Essential files preserved in root
if [[ -f "Dockerfile" && -f "Makefile" && -f "startup.sh" ]]; then
    test_result "Essential build files preserved in root" "PASS"
else
    test_result "Essential build files preserved in root" "FAIL"
fi

# Test 8: Shipwright structure preserved
if [[ -d "shipwright" && -f "shipwright/build.yaml" && -f "shipwright/buildrun.yaml" ]]; then
    test_result "Shipwright directory structure preserved" "PASS"
else
    test_result "Shipwright directory structure preserved" "FAIL"
fi

echo
echo "🔍 Testing Path Dependencies..."

# Test 9: Deploy scripts reference correct template path
if grep -q "../student-template.yaml" admin/deploy/deploy-bulk-students.sh; then
    test_result "Deploy scripts use correct template path" "PASS"
else
    test_result "Deploy scripts use correct template path" "FAIL"
fi

# Test 10: Build script references correct Shipwright paths
if grep -q "../../shipwright/" dev/build/build-and-verify.sh; then
    test_result "Build script uses correct Shipwright paths" "PASS"
else
    test_result "Build script uses correct Shipwright paths" "FAIL"
fi

# Test 11: Management scripts reference correct test framework
if grep -q "../validate/codeserver_test_framework.sh" admin/manage/complete-pod-refresh.sh; then
    test_result "Management scripts use correct test framework path" "PASS"
else
    test_result "Management scripts use correct test framework path" "FAIL"
fi

echo
echo "📚 Testing Documentation..."

# Test 12: READMEs exist
if [[ -f "admin/manage/README.md" ]]; then
    test_result "Admin management README exists" "PASS"
else
    test_result "Admin management README exists" "FAIL"
fi

echo
echo "📊 Validation Summary:"
echo "   Tests passed: $success_count/$total_tests"
echo "   Success rate: $(( success_count * 100 / total_tests ))%"

if [[ $success_count -eq $total_tests ]]; then
    echo -e "   ${GREEN}🎉 ALL TESTS PASSED - DOB-74 Structure Validation Complete!${NC}"
    echo
    echo "✅ Ready for functional testing:"
    echo "   1. Test build: cd dev/build && ./build-and-verify.sh"
    echo "   2. Test validation: cd admin/validate && ./codeserver_test_framework.sh auto"  
    echo "   3. Test deployment: ./admin-deploy.sh setup 1 3"
    exit 0
else
    echo -e "   ${RED}❌ Some tests failed - review structure before proceeding${NC}"
    exit 1
fi