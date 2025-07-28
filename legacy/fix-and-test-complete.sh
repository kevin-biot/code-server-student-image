#!/bin/bash
# fix-and-test-complete.sh - Fix any issues and test the complete student setup

set -e

echo "🔧 Fix and Test: Complete Student Setup"
echo "======================================="
echo ""

# Step 1: Check and fix common typos
echo "🔍 Step 1: Checking for common typos..."

SCRIPT_FILE="complete-student-setup-simple.sh"

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "❌ Script file not found: $SCRIPT_FILE"
    exit 1
fi

# Check for the specific typo mentioned: HTASSWD_FILE instead of HTPASSWD_FILE
if grep -q "HTASSWD_FILE" "$SCRIPT_FILE"; then
    echo "🔧 Fixing typo: HTASSWD_FILE -> HTPASSWD_FILE"
    sed -i.bak 's/HTASSWD_FILE/HTPASSWD_FILE/g' "$SCRIPT_FILE"
    echo "   ✅ Typo fixed (backup created as ${SCRIPT_FILE}.bak)"
else
    echo "   ✅ No HTASSWD_FILE typo found"
fi

# Check for other common variable typos
common_typos=(
    "s/HTPASWD_FILE/HTPASSWD_FILE/g"
    "s/HTPASSWD_FIEL/HTPASSWD_FILE/g"
    "s/HTPASSWD_FILR/HTPASSWD_FILE/g"
    "s/START_NUN/START_NUM/g"
    "s/END_NUN/END_NUM/g"
    "s/CLUSTER_DOMIAN/CLUSTER_DOMAIN/g"
)

for fix in "${common_typos[@]}"; do
    if sed -n "$fix p" "$SCRIPT_FILE" | grep -q .; then
        echo "🔧 Applying fix: $fix"
        sed -i.bak2 "$fix" "$SCRIPT_FILE"
    fi
done

echo "   ✅ Common typo check complete"
echo ""

# Step 2: Syntax validation
echo "🔍 Step 2: Bash syntax validation..."

if bash -n "$SCRIPT_FILE"; then
    echo "   ✅ Bash syntax is valid"
else
    echo "   ❌ Bash syntax errors found"
    exit 1
fi
echo ""

# Step 3: Make executable
echo "🔧 Step 3: Ensuring scripts are executable..."

chmod +x "$SCRIPT_FILE"
chmod +x "deploy-bulk-students.sh" 2>/dev/null || echo "   ⚠️  deploy-bulk-students.sh not found"
chmod +x "end-to-end-test.sh" 2>/dev/null || echo "   ⚠️  end-to-end-test.sh not found"

echo "   ✅ Scripts made executable"
echo ""

# Step 4: Pre-flight checks
echo "🔍 Step 4: Pre-flight environment checks..."

# Check OpenShift login
if ! oc whoami &>/dev/null; then
    echo "   ❌ Not logged in to OpenShift cluster"
    echo "      Please login with: oc login <cluster-url>"
    exit 1
fi

echo "   ✅ OpenShift login: $(oc whoami) @ $(oc cluster-info | head -1 | cut -d' ' -f6)"

# Check required commands
required_commands=("oc" "htpasswd" "seq" "printf")
for cmd in "${required_commands[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        echo "   ✅ $cmd command available"
    else
        echo "   ❌ $cmd command not found"
        exit 1
    fi
done
echo ""

# Step 5: Test with minimal set of students
echo "🧪 Step 5: Running test with 2 students..."

TEST_START=98
TEST_END=99

echo "   Testing with students: student$(printf "%02d" $TEST_START) to student$(printf "%02d" $TEST_END)"
echo "   This will not interfere with production students (01-25)"
echo ""

# Clean any existing test students
echo "   🧹 Cleaning previous test students..."
for i in $(seq $TEST_START $TEST_END); do
    student_name=$(printf "student%02d" $i)
    oc delete namespace "$student_name" --ignore-not-found=true &>/dev/null || true
    oc delete user "$student_name" --ignore-not-found=true &>/dev/null || true
    oc delete identity "htpasswd_provider:$student_name" --ignore-not-found=true &>/dev/null || true
done

# Run the setup script with test students
echo "   🚀 Running setup script..."
if ./"$SCRIPT_FILE" $TEST_START $TEST_END; then
    echo "   ✅ Setup script completed successfully"
else
    echo "   ❌ Setup script failed"
    exit 1
fi
echo ""

# Step 6: Validation
echo "🔍 Step 6: Validating test deployment..."

all_tests_passed=true

for i in $(seq $TEST_START $TEST_END); do
    student_name=$(printf "student%02d" $i)
    
    # Check namespace
    if oc get namespace "$student_name" &>/dev/null; then
        echo "   ✅ Namespace $student_name exists"
    else
        echo "   ❌ Namespace $student_name missing"
        all_tests_passed=false
    fi
    
    # Check user
    if oc get user "$student_name" &>/dev/null; then
        echo "   ✅ User $student_name exists"
    else
        echo "   ❌ User $student_name missing"
        all_tests_passed=false
    fi
    
    # Check RBAC
    if oc get rolebinding -n "$student_name" -o jsonpath='{.items[?(@.subjects[0].name=="'$student_name'")].metadata.name}' | grep -q admin; then
        echo "   ✅ $student_name has admin role in own namespace"
    else
        echo "   ❌ $student_name missing admin role"
        all_tests_passed=false
    fi
done

# Check OAuth
if oc get secret htpass-secret -n openshift-config &>/dev/null; then
    echo "   ✅ OAuth secret exists"
else
    echo "   ❌ OAuth secret missing"
    all_tests_passed=false
fi

# Test authentication for one student
TEST_STUDENT=$(printf "student%02d" $TEST_START)
echo "   🔑 Testing authentication for $TEST_STUDENT..."

# Store current login
CURRENT_USER=$(oc whoami)

if oc login --username="$TEST_STUDENT" --password="DevOps2025!" --insecure-skip-tls-verify=true &>/dev/null; then
    echo "   ✅ $TEST_STUDENT authentication successful"
    
    # Test namespace access
    if oc get pods -n "$TEST_STUDENT" &>/dev/null; then
        echo "   ✅ $TEST_STUDENT can access own namespace"
    else
        echo "   ❌ $TEST_STUDENT cannot access own namespace"
        all_tests_passed=false
    fi
    
    # Restore admin login
    oc login --username="$CURRENT_USER" --insecure-skip-tls-verify=true &>/dev/null || true
else
    echo "   ❌ $TEST_STUDENT authentication failed"
    all_tests_passed=false
fi
echo ""

# Step 7: Cleanup test students
echo "🧹 Step 7: Cleaning up test students..."

for i in $(seq $TEST_START $TEST_END); do
    student_name=$(printf "student%02d" $i)
    oc delete namespace "$student_name" --ignore-not-found=true &>/dev/null || true
    oc delete user "$student_name" --ignore-not-found=true &>/dev/null || true
    oc delete identity "htpasswd_provider:$student_name" --ignore-not-found=true &>/dev/null || true
    echo "   ✅ Cleaned $student_name"
done
echo ""

# Final report
echo "🎉 Fix and Test Complete!"
echo "========================"

if [ "$all_tests_passed" = true ]; then
    echo "✅ ALL TESTS PASSED"
    echo ""
    echo "🎓 The complete-student-setup-simple.sh script is ready for production!"
    echo ""
    echo "📝 To deploy for real bootcamp:"
    echo "   ./complete-student-setup-simple.sh 1 25"
    echo ""
    echo "📝 To test specific range:"
    echo "   ./complete-student-setup-simple.sh 1 3  # Test with first 3 students"
    echo ""
    echo "📝 To run comprehensive end-to-end test:"
    echo "   ./end-to-end-test.sh 1 3"
else
    echo "❌ SOME TESTS FAILED"
    echo ""
    echo "Please review the errors above and fix any issues before proceeding."
    exit 1
fi
