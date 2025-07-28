#!/bin/bash
# test-minimal-fix.sh - Test the minimal fix with students 98-99

echo "🧪 Testing Minimal Fix with Students 98-99"
echo "=========================================="
echo ""

# Clean up any existing test students first
echo "🧹 Cleaning up any existing test students..."
for i in 98 99; do
    student_name=$(printf "student%02d" $i)
    oc delete namespace "$student_name" --ignore-not-found=true
    oc delete user "$student_name" --ignore-not-found=true  
    oc delete identity "htpasswd_provider:$student_name" --ignore-not-found=true
done

echo "   ✅ Cleanup complete"
echo ""

# Make the fixed script executable
chmod +x complete-student-setup-simple-fixed.sh

# Run the test
echo "🚀 Running fixed script with students 98-99..."
echo "============================================="
./complete-student-setup-simple-fixed.sh 98 99

echo ""
echo "🎯 Test Complete!"
echo "================"
echo ""
echo "If successful, we can then apply the same fixes to your original script."
