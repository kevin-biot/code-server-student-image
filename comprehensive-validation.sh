#!/bin/bash
# comprehensive-validation.sh - Complete validation suite for code-server environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_DOMAIN=${1:-"apps.cluster.local"}
TEST_STUDENTS=${2:-1}

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

echo "============================================"
echo "Code Server Environment Validation Suite"
echo "============================================"
echo

# Phase 1: Prerequisites Check
info "Phase 1: Prerequisites Validation"
echo "-----------------------------------"

# Check required tools
for tool in oc kubectl tkn argocd pulumi helm; do
    if command -v "$tool" >/dev/null 2>&1; then
        version=$($tool version --client 2>/dev/null | head -n1 || $tool version 2>/dev/null | head -n1 || echo "unknown")
        log "$tool: $version"
    else
        error "$tool: not found"
    fi
done

# Check OpenShift connection
if oc whoami &>/dev/null; then
    log "OpenShift: Connected as $(oc whoami)"
else
    error "OpenShift: Not logged in"
    exit 1
fi

# Check devops namespace
if oc get namespace devops &>/dev/null; then
    log "devops namespace: exists"
else
    error "devops namespace: missing"
fi

# Check image stream
if oc get imagestream code-server-student -n devops &>/dev/null; then
    log "code-server-student image: available"
else
    warn "code-server-student image: not found - run build-and-verify.sh first"
fi

echo

# Phase 2: Deploy Test Students
info "Phase 2: Student Deployment Test"
echo "--------------------------------"

# Clean up any existing test students first
info "Cleaning up any existing test environments..."
for i in $(seq 1 $TEST_STUDENTS); do
    student_name=$(printf "test%02d" $i)
    oc delete namespace "$student_name" --ignore-not-found=true &
done
wait

# Deploy test students
info "Deploying $TEST_STUDENTS test student(s)..."
"$SCRIPT_DIR/deploy-students.sh" -s $(seq -s, -f "test%02g" 1 $TEST_STUDENTS) -d "$CLUSTER_DOMAIN"

# Wait for deployments
info "Waiting for deployments to be ready..."
for i in $(seq 1 $TEST_STUDENTS); do
    student_name=$(printf "test%02d" $i)
    if oc rollout status deployment/code-server -n "$student_name" --timeout=300s; then
        log "$student_name: deployment ready"
    else
        error "$student_name: deployment failed"
    fi
done

echo

# Phase 3: Environment Validation
info "Phase 3: Environment Validation"
echo "-------------------------------"

# Test first student environment
FIRST_STUDENT=$(printf "test%02d" 1)

# Get pod name
POD_NAME=$(oc get pods -n "$FIRST_STUDENT" -l app=code-server --no-headers -o custom-columns=":metadata.name" | head -n1)

if [ -z "$POD_NAME" ]; then
    error "No code-server pod found in $FIRST_STUDENT"
    exit 1
fi

log "Testing environment in $FIRST_STUDENT (pod: $POD_NAME)"

# Test CLI tools inside pod
info "Testing CLI tools in container..."
CLI_TESTS="
oc version --client
kubectl version --client
tkn version
pulumi version
argocd version --client
helm version --short
java -version
mvn -version
python3 --version
node --version
npm --version
git --version
"

echo "$CLI_TESTS" | while read -r cmd; do
    if [ -n "$cmd" ]; then
        if oc exec -n "$FIRST_STUDENT" "$POD_NAME" -- bash -c "$cmd" &>/dev/null; then
            log "  ✓ $cmd"
        else
            error "  ✗ $cmd"
        fi
    fi
done

# Test workspace structure
info "Testing workspace structure..."
WORKSPACE_DIRS="
/home/coder/workspace
/home/coder/workspace/labs
/home/coder/workspace/labs/day1-pulumi
/home/coder/workspace/labs/day2-tekton
/home/coder/workspace/labs/day3-gitops
/home/coder/workspace/projects
/home/coder/workspace/examples
/home/coder/workspace/templates
"

echo "$WORKSPACE_DIRS" | while read -r dir; do
    if [ -n "$dir" ]; then
        if oc exec -n "$FIRST_STUDENT" "$POD_NAME" -- test -d "$dir"; then
            log "  ✓ $dir"
        else
            error "  ✗ $dir"
        fi
    fi
done

# Test VS Code extensions
info "Testing VS Code extensions..."
EXPECTED_EXTENSIONS="
ms-python.python
redhat.vscode-yaml
ms-kubernetes-tools.vscode-kubernetes-tools
ms-azuretools.vscode-docker
vscjava.vscode-java-pack
"

echo "$EXPECTED_EXTENSIONS" | while read -r ext; do
    if [ -n "$ext" ]; then
        if oc exec -n "$FIRST_STUDENT" "$POD_NAME" -- code-server --list-extensions | grep -q "$ext"; then
            log "  ✓ $ext"
        else
            warn "  ! $ext (may not be critical)"
        fi
    fi
done

echo

# Phase 4: Network and Access Testing
info "Phase 4: Network and Access Testing"
echo "----------------------------------"

for i in $(seq 1 $TEST_STUDENTS); do
    student_name=$(printf "test%02d" $i)
    
    # Test route accessibility
    route_host=$(oc get route code-server -n "$student_name" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
    
    if [ -n "$route_host" ]; then
        log "$student_name: route configured (https://$route_host)"
        
        # Test HTTP response (don't follow redirects, just check if route responds)
        if curl -k -s -o /dev/null -w "%{http_code}" "https://$route_host" | grep -q "200\|302\|401"; then
            log "  ✓ Route responds to HTTP requests"
        else
            warn "  ! Route may not be accessible externally"
        fi
    else
        error "$student_name: no route found"
    fi
    
    # Test resource quotas
    if oc get resourcequota -n "$student_name" &>/dev/null; then
        log "  ✓ Resource quota configured"
    else
        warn "  ! No resource quota found"
    fi
    
    # Test network policy
    if oc get networkpolicy -n "$student_name" &>/dev/null; then
        log "  ✓ Network policy configured"
    else
        warn "  ! No network policy found"
    fi
done

echo

# Phase 5: Workshop Content Validation
info "Phase 5: Workshop Content Validation"
echo "-----------------------------------"

# Test Day 1 content
if oc exec -n "$FIRST_STUDENT" "$POD_NAME" -- test -f /home/coder/workspace/labs/day1-pulumi/package.json; then
    log "Day 1 Pulumi: package.json present"
    
    # Test npm install
    if oc exec -n "$FIRST_STUDENT" "$POD_NAME" -- bash -c "cd /home/coder/workspace/labs/day1-pulumi && npm install" &>/dev/null; then
        log "  ✓ npm install successful"
    else
        warn "  ! npm install failed"
    fi
else
    error "Day 1 Pulumi: package.json missing"
fi

# Test README files
for day in day1-pulumi day2-tekton day3-gitops; do
    if oc exec -n "$FIRST_STUDENT" "$POD_NAME" -- test -f "/home/coder/workspace/labs/$day/README.md"; then
        log "$day: README.md present"
    else
        warn "$day: README.md missing"
    fi
done

echo

# Phase 6: Resource Usage Check
info "Phase 6: Resource Usage Analysis"
echo "-------------------------------"

# Check node resources
info "Cluster resource usage:"
oc top nodes | head -n 5

# Check student pod resources
info "Student pod resource usage:"
for i in $(seq 1 $TEST_STUDENTS); do
    student_name=$(printf "test%02d" $i)
    usage=$(oc top pod -n "$student_name" --no-headers 2>/dev/null | head -n1)
    if [ -n "$usage" ]; then
        log "$student_name: $usage"
    else
        warn "$student_name: no resource data available"
    fi
done

echo

# Phase 7: Credentials and Access
info "Phase 7: Credentials and Access Information"
echo "-----------------------------------------"

if [ -f "$SCRIPT_DIR/student-credentials.txt" ]; then
    log "Credentials file exists"
    info "Recent credentials (last 5 entries):"
    tail -n 5 "$SCRIPT_DIR/student-credentials.txt" | grep -v "^#" | while read -r line; do
        if [ -n "$line" ]; then
            echo "  $line"
        fi
    done
else
    warn "No credentials file found"
fi

echo

# Summary
echo "============================================"
echo "Validation Summary"
echo "============================================"

# Quick status check
RUNNING_PODS=$(oc get pods -A -l app=code-server --no-headers | grep Running | wc -l)
TOTAL_PODS=$(oc get pods -A -l app=code-server --no-headers | wc -l)

log "Student environments: $RUNNING_PODS/$TOTAL_PODS running"

if [ "$RUNNING_PODS" -eq "$TEST_STUDENTS" ]; then
    log "✅ All test environments are running successfully!"
    log "Next steps:"
    echo "  1. Access environments using URLs in student-credentials.txt"
    echo "  2. Test workshop content manually in browser"
    echo "  3. Scale test with more students: $0 $CLUSTER_DOMAIN 5"
    echo "  4. Clean up test environments: ./deploy-students.sh -s $(seq -s, -f "test%02g" 1 $TEST_STUDENTS) --cleanup"
else
    warn "⚠️  Some environments may need attention"
    info "Check logs with: oc logs -l app=code-server -n test01"
fi

echo "Validation complete!"
