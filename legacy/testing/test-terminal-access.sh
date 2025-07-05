#!/bin/bash
# test-terminal-access.sh - Quick test to verify terminal tools work in student environment

set -e

STUDENT_NS=${1:-"student01"}

echo "Testing terminal access in student environment: $STUDENT_NS"
echo "================================================================"

# Get the running pod
POD_NAME=$(oc get pods -n "$STUDENT_NS" -l app=code-server --no-headers -o custom-columns=":metadata.name" | head -n1)

if [ -z "$POD_NAME" ]; then
    echo "❌ No code-server pod found in namespace $STUDENT_NS"
    echo "Run this first: ./deploy-students.sh -n 1 -d your-cluster-domain.com"
    exit 1
fi

echo "📱 Found pod: $POD_NAME"
echo

# Test basic terminal functionality
echo "🔧 Testing CLI tools accessibility..."
echo "------------------------------------"

# Array of tools to test with their expected output patterns
declare -A TOOLS=(
    ["oc"]="version"
    ["kubectl"]="version"
    ["tkn"]="version"
    ["pulumi"]="version"
    ["argocd"]="version"
    ["helm"]="version"
    ["java"]="version"
    ["mvn"]="version"
    ["python3"]="version"
    ["node"]="version"
    ["npm"]="version"
    ["git"]="version"
)

for tool in "${!TOOLS[@]}"; do
    echo -n "  Testing $tool: "
    
    if oc exec -n "$STUDENT_NS" "$POD_NAME" -- which "$tool" >/dev/null 2>&1; then
        # Tool exists, test if it runs
        if oc exec -n "$STUDENT_NS" "$POD_NAME" -- "$tool" --version >/dev/null 2>&1; then
            echo "✅ Working"
        elif oc exec -n "$STUDENT_NS" "$POD_NAME" -- "$tool" version >/dev/null 2>&1; then
            echo "✅ Working"
        else
            echo "⚠️  Found but may have issues"
        fi
    else
        echo "❌ Not found"
    fi
done

echo
echo "🌐 Testing workspace structure..."
echo "--------------------------------"

# Test key directories
WORKSPACE_DIRS=(
    "/home/coder/workspace"
    "/home/coder/workspace/labs"
    "/home/coder/workspace/labs/day1-pulumi"
    "/home/coder/workspace/labs/day2-tekton"
    "/home/coder/workspace/labs/day3-gitops"
    "/home/coder/workspace/projects"
)

for dir in "${WORKSPACE_DIRS[@]}"; do
    echo -n "  $dir: "
    if oc exec -n "$STUDENT_NS" "$POD_NAME" -- test -d "$dir"; then
        echo "✅ Exists"
    else
        echo "❌ Missing"
    fi
done

echo
echo "📝 Testing workshop files..."
echo "---------------------------"

# Test key workshop files
WORKSHOP_FILES=(
    "/home/coder/workspace/README.md"
    "/home/coder/workspace/labs/day1-pulumi/package.json"
    "/home/coder/workspace/labs/day1-pulumi/README.md"
    "/home/coder/workspace/labs/day2-tekton/README.md"
    "/home/coder/workspace/labs/day3-gitops/README.md"
)

for file in "${WORKSHOP_FILES[@]}"; do
    echo -n "  $(basename "$file"): "
    if oc exec -n "$STUDENT_NS" "$POD_NAME" -- test -f "$file"; then
        echo "✅ Present"
    else
        echo "⚠️  Missing"
    fi
done

echo
echo "🔗 Testing route access..."
echo "-------------------------"

ROUTE_HOST=$(oc get route code-server -n "$STUDENT_NS" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")

if [ -n "$ROUTE_HOST" ]; then
    echo "  Route URL: https://$ROUTE_HOST"
    
    # Test if route responds
    HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" "https://$ROUTE_HOST" 2>/dev/null || echo "000")
    
    case "$HTTP_CODE" in
        200) echo "  Status: ✅ Accessible (200 OK)" ;;
        302|301) echo "  Status: ✅ Accessible (redirecting)" ;;
        401) echo "  Status: ✅ Accessible (auth required)" ;;
        000) echo "  Status: ❌ Network error" ;;
        *) echo "  Status: ⚠️  HTTP $HTTP_CODE" ;;
    esac
else
    echo "  ❌ No route found"
fi

echo
echo "🔐 Getting access credentials..."
echo "------------------------------"

if [ -f "student-credentials.txt" ]; then
    echo "  Checking credentials file..."
    CRED_LINE=$(grep "$STUDENT_NS" student-credentials.txt | head -n1)
    if [ -n "$CRED_LINE" ]; then
        echo "  ✅ Credentials found:"
        echo "      $CRED_LINE"
    else
        echo "  ⚠️  No credentials found for $STUDENT_NS in file"
    fi
else
    echo "  ⚠️  No student-credentials.txt file found"
fi

echo
echo "============================================"
echo "Summary"
echo "============================================"

# Get pod status
POD_STATUS=$(oc get pod "$POD_NAME" -n "$STUDENT_NS" --no-headers -o custom-columns=":status.phase")
echo "Pod Status: $POD_STATUS"

if [ "$POD_STATUS" = "Running" ]; then
    echo "✅ Student environment is ready!"
    echo
    echo "Next steps:"
    echo "1. Access the environment via the route URL above"
    echo "2. Login with the password from credentials"
    echo "3. Open terminal in VS Code: Terminal → New Terminal"
    echo "4. Test commands like: oc whoami, kubectl version, etc."
    echo
    echo "To test interactively:"
    echo "  oc rsh -n $STUDENT_NS $POD_NAME"
else
    echo "❌ Student environment needs attention"
    echo "Check logs: oc logs -n $STUDENT_NS $POD_NAME"
fi
