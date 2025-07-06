#!/bin/bash
# validate-script.sh - Check for common issues in the setup script

echo "🔍 Script Validation Tool"
echo "========================"

SCRIPT_FILE="complete-student-setup-simple.sh"

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "❌ Script file not found: $SCRIPT_FILE"
    exit 1
fi

echo "✅ Script file found: $SCRIPT_FILE"
echo ""

# Check 1: Syntax validation
echo "🔧 Check 1: Bash Syntax Validation"
echo "=================================="
if bash -n "$SCRIPT_FILE"; then
    echo "✅ Bash syntax is valid"
else
    echo "❌ Bash syntax errors found"
    exit 1
fi
echo ""

# Check 2: Variable consistency
echo "🔧 Check 2: Variable Consistency"
echo "==============================="

# Extract all variable definitions
echo "Variable definitions found:"
grep -n "^[A-Z_]*=" "$SCRIPT_FILE" | while read line; do
    echo "   $line"
done
echo ""

# Check for common typos in HTPASSWD_FILE
echo "HTPASSWD_FILE usage check:"
grep -n "HTPASSWD_FILE\|HTASSWD_FILE" "$SCRIPT_FILE" | while read line; do
    line_num=$(echo "$line" | cut -d: -f1)
    content=$(echo "$line" | cut -d: -f2-)
    
    if echo "$content" | grep -q "HTASSWD_FILE"; then
        echo "   ❌ Line $line_num: TYPO FOUND - Missing 'P' in HTPASSWD_FILE"
        echo "      $content"
    else
        echo "   ✅ Line $line_num: Correct spelling"
        echo "      $content"
    fi
done
echo ""

# Check 3: Required commands
echo "🔧 Check 3: Required Command Availability"
echo "========================================"

commands=("oc" "htpasswd" "seq" "printf")
for cmd in "${commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "   ✅ $cmd is available"
    else
        echo "   ❌ $cmd is NOT available"
    fi
done
echo ""

# Check 4: File permissions
echo "🔧 Check 4: File Permissions"
echo "============================"
if [ -x "$SCRIPT_FILE" ]; then
    echo "   ✅ Script is executable"
else
    echo "   ⚠️  Script is not executable - run: chmod +x $SCRIPT_FILE"
fi
echo ""

# Check 5: Variable usage
echo "🔧 Check 5: Variable Usage Analysis"
echo "==================================="

# Check if all defined variables are used
defined_vars=$(grep -o "^[A-Z_]*=" "$SCRIPT_FILE" | sed 's/=$//')
for var in $defined_vars; do
    usage_count=$(grep -c "\${$var}\|\$$var" "$SCRIPT_FILE" || echo "0")
    if [ "$usage_count" -gt 0 ]; then
        echo "   ✅ $var is used ($usage_count times)"
    else
        echo "   ⚠️  $var is defined but not used"
    fi
done
echo ""

# Check 6: Critical path analysis
echo "🔧 Check 6: Critical Path Analysis"
echo "=================================="

critical_files=("./deploy-bulk-students.sh")
for file in "${critical_files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ Dependency found: $file"
    else
        echo "   ❌ Missing dependency: $file"
    fi
done
echo ""

echo "🎯 Validation Complete!"
echo "======================"
