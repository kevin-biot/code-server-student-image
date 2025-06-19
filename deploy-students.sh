#!/bin/bash
# deploy-students.sh - Deploy multiple student environments

set -e

# Verify required commands are available
REQUIRED_CMDS=("oc" "openssl")
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: required command '$cmd' not found in PATH." >&2
        exit 1
    fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/student-template.yaml"
CLUSTER_DOMAIN=${CLUSTER_DOMAIN:-"apps.cluster.local"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy code-server environments for multiple students

Options:
    -s, --students LIST     Comma-separated list of student names (e.g., student01,student02)
    -n, --number NUM        Create numbered students from student01 to studentNN
    -d, --domain DOMAIN     OpenShift cluster domain (default: apps.cluster.local)
    -i, --image IMAGE       Code-server image to use
    --cleanup               Clean up (delete) student environments
    -f, --force             Redeploy even if namespace already exists
    -h, --help              Show this help message

Examples:
    $0 -n 10                          # Create student01 through student10
    $0 -s student01,student05,john    # Create specific students
    $0 -n 5 -d apps.ocp.example.com  # Create 5 students with custom domain
    $0 -n 5 --cleanup                # Delete student01 through student05

EOF
}

deploy_student() {
    local student_name=$1
    local password=$2
    
    log "Deploying environment for ${student_name}..."
    
    # Process template and apply
    if ! oc process -f "${TEMPLATE_FILE}" \
        -p STUDENT_NAME="${student_name}" \
        -p STUDENT_PASSWORD="${password}" \
        -p CLUSTER_DOMAIN="${CLUSTER_DOMAIN}" \
        -p IMAGE_NAME="${IMAGE_NAME:-image-registry.openshift-image-registry.svc:5000/devops/code-server-student:latest}" \
        | oc apply -f -; then
        error "Failed to apply template for ${student_name}"
        return 1
    fi
    
    # Wait for deployment to be ready with better feedback
    log "Waiting for ${student_name} deployment to be ready..."
    
    # Check deployment status with timeout
    local timeout=300
    local elapsed=0
    local interval=10
    
    while [[ $elapsed -lt $timeout ]]; do
        local ready_replicas=$(oc get deployment code-server -n "${student_name}" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired_replicas=$(oc get deployment code-server -n "${student_name}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
        
        if [[ "${ready_replicas}" == "${desired_replicas}" ]]; then
            log "✅ ${student_name} deployment is ready!"
            break
        fi
        
        # Show current status
        local pod_status=$(oc get pods -n "${student_name}" -l app=code-server --no-headers 2>/dev/null | awk '{print $3}' | head -1)
        log "⏳ ${student_name}: Pod status: ${pod_status:-"Unknown"} (${elapsed}s/${timeout}s)"
        
        # Check for common issues
        if [[ $elapsed -gt 60 ]]; then
            local events=$(oc get events -n "${student_name}" --sort-by='.lastTimestamp' --no-headers | tail -3 | awk '{print $6,$7,$8,$9,$10}')
            if [[ -n "$events" ]]; then
                warn "Recent events: $events"
            fi
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    if [[ $elapsed -ge $timeout ]]; then
        error "Timeout waiting for ${student_name} deployment. Check 'oc get pods -n ${student_name}' for details."
        return 1
    fi
    
    # Verify service endpoints
    local endpoints=$(oc get endpoints code-server -n "${student_name}" -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
    if [[ -z "$endpoints" ]]; then
        warn "No service endpoints found for ${student_name}. Service may not be working correctly."
    fi
    
    # Get route URL
    local route_url=$(oc get route code-server -n "${student_name}" -o jsonpath='{.spec.host}' 2>/dev/null)
    
    if [[ -z "$route_url" ]]; then
        error "Failed to get route URL for ${student_name}"
        return 1
    fi
    
    log "✅ ${student_name} deployed successfully!"
    echo "Student: ${student_name}"
    echo "  URL: https://${route_url}"
    echo "  Password: ${password}"
    echo ""
    
    return 0
}

generate_password() {
    openssl rand -base64 12 | tr -d "=+/" | cut -c1-12
}

cleanup_student() {
    local student_name=$1
    warn "Cleaning up environment for ${student_name}..."
    oc delete namespace "${student_name}" --ignore-not-found=true
}

# Parse command line arguments
STUDENTS=""
NUMBER=""
IMAGE_NAME=""
CLEANUP=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--students)
            STUDENTS="$2"
            shift 2
            ;;
        -n|--number)
            NUMBER="$2"
            shift 2
            ;;
        -d|--domain)
            CLUSTER_DOMAIN="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --cleanup)
            CLEANUP=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

# Check if template exists
if [[ ! -f "${TEMPLATE_FILE}" ]]; then
    error "Template file not found: ${TEMPLATE_FILE}"
    exit 1
fi

# Ensure we're logged into OpenShift
if ! oc whoami &> /dev/null; then
    error "Not logged into OpenShift. Please run 'oc login' first."
    exit 1
fi

# Generate student list
student_list=()
if [[ -n "${NUMBER}" ]]; then
    for ((i=1; i<=NUMBER; i++)); do
        student_list+=("$(printf "student%02d" $i)")
    done
elif [[ -n "${STUDENTS}" ]]; then
    IFS=',' read -ra student_list <<< "${STUDENTS}"
else
    error "Either --students or --number must be specified"
    usage
    exit 1
fi

# Create credentials file
CREDS_FILE="${SCRIPT_DIR}/student-credentials.txt"
if [[ "${CLEANUP}" != "true" ]]; then
    echo "# Student Credentials - $(date)" > "${CREDS_FILE}"
    echo "# Format: Student | URL | Password" >> "${CREDS_FILE}"
    echo "" >> "${CREDS_FILE}"
fi

log "Processing ${#student_list[@]} student environments..."

for student in "${student_list[@]}"; do
    if [[ "${CLEANUP}" == "true" ]]; then
        cleanup_student "${student}"
    else
        # Check if the namespace already exists and skip unless forcing.
        # Example: oc get namespace "${student}" >/dev/null 2>&1
        if oc get namespace "${student}" >/dev/null 2>&1; then
            if [[ "${FORCE}" != "true" ]]; then
                warn "Namespace ${student} already exists. Skipping deployment. Use --force to redeploy."
                continue
            else
                warn "Namespace ${student} already exists but --force specified. Redeploying."
            fi
        fi

        password=$(generate_password)
        deploy_student "${student}" "${password}"
        
        # Save credentials
        route_url=$(oc get route code-server -n "${student}" -o jsonpath='{.spec.host}' 2>/dev/null || echo "pending")
        echo "${student} | https://${route_url} | ${password}" >> "${CREDS_FILE}"
    fi
done

if [[ "${CLEANUP}" != "true" ]]; then
    log "All student environments deployed successfully!"
    log "Credentials saved to: ${CREDS_FILE}"
    
    echo ""
    echo "Summary:"
    cat "${CREDS_FILE}" | tail -n +4
else
    log "Cleanup completed for all specified student environments."
fi
