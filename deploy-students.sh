#!/bin/bash
# deploy-students.sh - Deploy multiple student environments

set -e

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
    oc process -f "${TEMPLATE_FILE}" \
        -p STUDENT_NAME="${student_name}" \
        -p STUDENT_PASSWORD="${password}" \
        -p CLUSTER_DOMAIN="${CLUSTER_DOMAIN}" \
        -p IMAGE_NAME="${IMAGE_NAME:-image-registry.openshift-image-registry.svc:5000/devops/code-server-student:latest}" \
        | oc apply -f -
    
    # Wait for deployment to be ready
    log "Waiting for ${student_name} deployment to be ready..."
    oc rollout status deployment/code-server -n "${student_name}" --timeout=300s
    
    # Get route URL
    local route_url=$(oc get route code-server -n "${student_name}" -o jsonpath='{.spec.host}')
    
    echo "Student: ${student_name}"
    echo "  URL: https://${route_url}"
    echo "  Password: ${password}"
    echo ""
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
