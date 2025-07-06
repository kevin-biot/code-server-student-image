#!/bin/bash
# apply-minimal-fix.sh - Apply the minimal htpasswd fix to the original script

echo "🔧 Applying Minimal HTPasswd Fix to Original Script"
echo "=================================================="
echo ""

# Backup the original script first
if [ ! -f "complete-student-setup-simple.sh.backup" ]; then
    echo "📋 Creating backup of original script..."
    cp complete-student-setup-simple.sh complete-student-setup-simple.sh.backup
    echo "   ✅ Backup created: complete-student-setup-simple.sh.backup"
else
    echo "   ✅ Backup already exists: complete-student-setup-simple.sh.backup"
fi
echo ""

echo "🔧 Applying htpasswd syntax fixes..."

# Fix 1: Change htpasswd -Bc to htpasswd -c -b -B (line ~33)
sed -i.tmp1 's/htpasswd -Bc /htpasswd -c -b -B /g' complete-student-setup-simple.sh

# Fix 2: Change htpasswd -Bb to htpasswd -b -B (line ~36) 
sed -i.tmp2 's/htpasswd -Bb /htpasswd -b -B /g' complete-student-setup-simple.sh

# Remove temporary files
rm -f complete-student-setup-simple.sh.tmp1 complete-student-setup-simple.sh.tmp2

echo "   ✅ HTPasswd command syntax fixed"
echo ""

echo "🔍 Verifying changes..."
echo "Searching for htpasswd commands in the fixed script:"
grep -n "htpasswd.*-" complete-student-setup-simple.sh | sed 's/^/   /'
echo ""

echo "✅ Minimal fix applied successfully!"
echo ""
echo "📋 Changes made:"
echo "   1. htpasswd -Bc → htpasswd -c -b -B (create first user)"
echo "   2. htpasswd -Bb → htpasswd -b -B (add additional users)"
echo ""
echo "🚀 Ready to test your sequence:"
echo "   1. ./build-and-verify.sh"
echo "   2. ./complete-student-setup-simple.sh 1 5"
echo "   3. ./test-deployment.sh student01"
echo "   4. oc login -u student01 -p 'DevOps2025!'"
echo ""
echo "📁 Files:"
echo "   Original backup: complete-student-setup-simple.sh.backup"
echo "   Fixed script: complete-student-setup-simple.sh"
