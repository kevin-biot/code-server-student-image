#!/bin/bash
# test-student-experience.sh - Complete end-to-end test of student experience

set -e

CLUSTER_DOMAIN=${1:-"apps.cluster.local"}
TEST_STUDENT=${2:-"testuser"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

echo "=========================================="
echo "Student Experience End-to-End Test"
echo "=========================================="
echo "Testing student: $TEST_STUDENT"
echo "Cluster domain: $CLUSTER_DOMAIN"
echo

# Clean up any existing test student
info "Cleaning up any existing test student..."
oc delete namespace "$TEST_STUDENT" --ignore-not-found=true
echo "Waiting for cleanup to complete..."
while oc get namespace "$TEST_STUDENT" &>/dev/null; do
    echo -n "."
    sleep 2
done
echo

# Deploy fresh test student
info "Deploying fresh test student environment..."
./deploy-students.sh -s "$TEST_STUDENT" -d "$CLUSTER_DOMAIN"

# Wait for deployment to be ready
info "Waiting for deployment to be ready..."
if oc rollout status deployment/code-server -n "$TEST_STUDENT" --timeout=300s; then
    log "Deployment ready"
else
    error "Deployment failed"
    exit 1
fi

# Get pod name
POD_NAME=$(oc get pods -n "$TEST_STUDENT" -l app=code-server --no-headers -o custom-columns=":metadata.name" | head -n1)
if [ -z "$POD_NAME" ]; then
    error "No pod found"
    exit 1
fi

log "Testing pod: $POD_NAME"

echo
info "Testing Student Quick Start Guide Integration..."
echo "=============================================="

# Test 1: Quick start guide exists in workspace
info "1. Checking if STUDENT-QUICK-START.md exists in workspace..."
if oc exec -n "$TEST_STUDENT" "$POD_NAME" -- test -f /home/coder/workspace/STUDENT-QUICK-START.md; then
    log "✓ STUDENT-QUICK-START.md found in workspace"
else
    error "✗ STUDENT-QUICK-START.md missing from workspace"
fi

# Test 2: Main README references quick start
info "2. Checking main README mentions quick start guide..."
if oc exec -n "$TEST_STUDENT" "$POD_NAME" -- grep -q "STUDENT-QUICK-START" /home/coder/workspace/README.md; then
    log "✓ Main README references quick start guide"
else
    warn "! Main README may not reference quick start guide"
fi

# Test 3: File structure matches guide
info "3. Verifying workspace structure matches guide..."
EXPECTED_DIRS=(
    "/home/coder/workspace"
    "/home/coder/workspace/labs"
    "/home/coder/workspace/labs/day1-pulumi"
    "/home/coder/workspace/labs/day2-tekton"
    "/home/coder/workspace/labs/day3-gitops"
    "/home/coder/workspace/projects"
    "/home/coder/workspace/examples"
)

for dir in "${EXPECTED_DIRS[@]}"; do
    if oc exec -n "$TEST_STUDENT" "$POD_NAME" -- test -d "$dir"; then
        log "  ✓ $dir"
    else
        error "  ✗ $dir"
    fi
done

echo
info "Testing DevOps Tools (as mentioned in quick start)..."
echo "=================================================="

# Test tools mentioned in quick start guide
TOOLS=(
    "oc version --client"
    "kubectl version --client"
    "tkn version"
    "pulumi version"
    "argocd version --client"
    "helm version --short"
    "java -version"
    "mvn -version"
    "python3 --version"
    "node --version"
    "npm --version"
    "git --version"
)

for tool_cmd in "${TOOLS[@]}"; do
    tool_name=$(echo "$tool_cmd" | cut -d' ' -f1)
    info "Testing $tool_name..."
    
    if oc exec -n "$TEST_STUDENT" "$POD_NAME" -- bash -c "$tool_cmd" &>/dev/null; then
        log "  ✓ $tool_name works"
    else
        error "  ✗ $tool_name failed"
    fi
done

echo
info "Testing Workshop Content Setup..."
echo "==============================="

# Test Day 1 Pulumi setup
info "4. Testing Day 1 Pulumi setup..."
if oc exec -n "$TEST_STUDENT" "$POD_NAME" -- test -f /home/coder/workspace/labs/day1-pulumi/package.json; then
    log "✓ Day 1 package.json exists"
    
    # Test npm install as mentioned in guide
    if oc exec -n "$TEST_STUDENT" "$POD_NAME" -- bash -c "cd /home/coder/workspace/labs/day1-pulumi && timeout 60 npm install" &>/dev/null; then
        log "✓ npm install works (as shown in quick start)"
    else
        warn "! npm install may have issues"
    fi
else
    error "✗ Day 1 package.json missing"
fi

# Test README files exist
for day in day1-pulumi day2-tekton day3-gitops; do
    if oc exec -n "$TEST_STUDENT" "$POD_NAME" -- test -f "/home/coder/workspace/labs/$day/README.md"; then
        log "✓ $day README exists"
    else
        warn "! $day README missing"
    fi
done

echo
info "Testing Student Commands from Quick Start..."
echo "=========================================="

# Test basic commands from the quick start guide
info "5. Testing basic navigation commands..."
BASIC_COMMANDS=(
    "pwd"
    "ls"
    "ls -la"
    "cd /home/coder/workspace && pwd"
    "ls labs/"
)

for cmd in "${BASIC_COMMANDS[@]}"; do
    if oc exec -n "$TEST_STUDENT" "$POD_NAME" -- bash -c "$cmd" &>/dev/null; then
        log "  ✓ '$cmd' works"
    else
        error "  ✗ '$cmd' failed"
    fi
done

# Test DevOps commands from quick start
info "6. Testing DevOps commands..."
DEVOPS_COMMANDS=(
    "oc whoami"
    "oc project"
    "oc get pods"
)

for cmd in "${DEVOPS_COMMANDS[@]}"; do
    if oc exec -n "$TEST_STUDENT" "$POD_NAME" -- bash -c "$cmd" &>/dev/null; then
        log "  ✓ '$cmd' works"
    else
        warn "  ! '$cmd' needs OpenShift login (expected)"
    fi
done

echo
info "Testing External Accessibility..."
echo "==============================="

# Test route accessibility
ROUTE_HOST=$(oc get route code-server -n "$TEST_STUDENT" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")

if [ -n "$ROUTE_HOST" ]; then
    log "Route configured: https://$ROUTE_HOST"
    
    # Test HTTP response
    HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" "https://$ROUTE_HOST" 2>/dev/null || echo "000")
    
    case "$HTTP_CODE" in
        200) log "✓ Route accessible (200 OK)" ;;
        302|301) log "✓ Route accessible (redirecting)" ;;
        401) log "✓ Route accessible (password required - correct!)" ;;
        000) error "✗ Route not accessible" ;;
        *) warn "! Route returns HTTP $HTTP_CODE" ;;
    esac
else
    error "✗ No route found"
fi

echo
info "Retrieving Student Credentials..."
echo "==============================="

if [ -f "student-credentials.txt" ]; then
    CRED_LINE=$(grep "$TEST_STUDENT" student-credentials.txt | head -n1)
    if [ -n "$CRED_LINE" ]; then
        log "Student credentials found:"
        echo "  $CRED_LINE"
        
        # Extract password for display
        PASSWORD=$(echo "$CRED_LINE" | cut -d'|' -f3 | tr -d ' ')
        URL=$(echo "$CRED_LINE" | cut -d'|' -f2 | tr -d ' ')
        
        echo
        info "=== MANUAL TEST INSTRUCTIONS ==="
        echo "1. Open browser and go to: $URL"
        echo "2. Enter password: $PASSWORD"
        echo "3. Look for 'STUDENT-QUICK-START.md' in file explorer"
        echo "4. Click on it to open"
        echo "5. Follow the guide to open terminal: Ctrl+Shift+\`"
        echo "6. Test commands from the guide"
        echo
    else
        error "No credentials found for $TEST_STUDENT"
    fi
else
    error "No credentials file found"
fi

echo
echo "=========================================="
echo "Test Summary"
echo "=========================================="

# Get final status
POD_STATUS=$(oc get pod "$POD_NAME" -n "$TEST_STUDENT" --no-headers -o custom-columns=":status.phase")
READY_REPLICAS=$(oc get deployment code-server -n "$TEST_STUDENT" --no-headers -o custom-columns=":status.readyReplicas")

log "Pod Status: $POD_STATUS"
log "Ready Replicas: ${READY_REPLICAS:-0}/1"

if [ "$POD_STATUS" = "Running" ] && [ "${READY_REPLICAS:-0}" = "1" ]; then
    echo
    log "🎉 STUDENT ENVIRONMENT READY!"
    echo
    echo "Next steps:"
    echo "1. Manually test the browser experience using the URL above"
    echo "2. Verify the STUDENT-QUICK-START.md guide is helpful"
    echo "3. Test the terminal and basic commands"
    echo "4. If successful, deploy your full class:"
    echo "   ./deploy-students.sh -n 20 -d $CLUSTER_DOMAIN"
else
    echo
    error "❌ Environment has issues - check logs:"
    echo "oc logs -n $TEST_STUDENT $POD_NAME"
fi

echo
echo "Clean up test environment:"
echo "  oc delete namespace $TEST_STUDENT"
echo
echo "Student experience test complete!"
