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
TEMPLATE_FILE="${SCRIPT_DIR}/../student-template.yaml"
CLUSTER_DOMAIN=${CLUSTER_DOMAIN:-"apps.cluster.local"}
STORAGE_CLASS=${STORAGE_CLASS:-""}

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
        --console-access        Create OpenShift console users for students
        --console-password PWD  Password for OpenShift console (default: workshop123)
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

# NEW: Auto-detect OAuth provider name
get_oauth_provider_name() {
    local provider_name=$(oc get oauth cluster -o jsonpath='{.spec.identityProviders[0].name}' 2>/dev/null)
    if [[ -z "$provider_name" ]]; then
        # Default fallback
        provider_name="htpasswd_provider"
        warn "Could not detect OAuth provider name, using default: ${provider_name}"
    else
        log "🔍 Detected OAuth provider name: ${provider_name}"
    fi
    echo "$provider_name"
}

# NEW: Update htpasswd secret with student password
update_htpasswd_secret() {
    local student_name=$1
    local password=$2
    
    log "🔐 Adding ${student_name} to htpasswd secret..."
    
    # Get current htpasswd content (may be empty)
    local temp_file="/tmp/htpasswd-update-$"
    oc get secret htpass-secret -n openshift-config -o jsonpath='{.data.htpasswd}' 2>/dev/null | base64 -d > "$temp_file" || touch "$temp_file"
    
    # Add or update the student
    htpasswd -bB "$temp_file" "$student_name" "$password"
    
    # Update the secret
    oc create secret generic htpass-secret \
        --from-file=htpasswd="$temp_file" \
        -n openshift-config \
        --dry-run=client -o yaml | oc replace -f -
    
    # Clean up
    rm -f "$temp_file"
    
    log "✅ Updated htpasswd secret with ${student_name}"
}

create_console_user() {
    local student_name=$1
    local console_password=$2
    
    log "🔐 Creating OpenShift console user: ${student_name}"
    
    # Get the current OAuth provider name
    local oauth_provider=$(get_oauth_provider_name)
    
    # Create user and identity (ignore errors if already exists)
    oc create user "${student_name}" 2>/dev/null || true
    oc create identity "${oauth_provider}:${student_name}" 2>/dev/null || true
    oc create useridentitymapping "${oauth_provider}:${student_name}" "${student_name}" 2>/dev/null || true
    
    # Update htpasswd secret with password
    update_htpasswd_secret "${student_name}" "${console_password}"
    
    # Grant admin access to their namespace
    oc adm policy add-role-to-user admin "${student_name}" -n "${student_name}" 2>/dev/null || true
    
    # Grant view access to tekton-pipelines namespace for dashboard
    oc adm policy add-role-to-user view "${student_name}" -n openshift-pipelines 2>/dev/null || true
    
    log "✅ Console user created - Username: ${student_name}, Password: ${console_password}"
}

deploy_student() {
    local student_name=$1
    local password=$2
    
    log "Deploying environment for ${student_name}..."
    
    # Create OpenShift console user if requested
    if [[ "${CREATE_CONSOLE_USERS}" == "true" ]]; then
        create_console_user "${student_name}" "${CONSOLE_PASSWORD}"
    fi
    
    # Ensure student namespace can pull from devops registry
    if ! oc policy add-role-to-user system:image-puller "system:serviceaccount:${student_name}:default" -n devops >/dev/null 2>&1; then
        warn "Could not grant image pull permissions to ${student_name}"
    fi
    
    # Auto-detect storage class if not specified
    local storage_class="${STORAGE_CLASS}"
    if [[ -z "$storage_class" ]]; then
        # Check for CRC environment
        if oc get storageclass crc-csi-hostpath-provisioner >/dev/null 2>&1; then
            storage_class="crc-csi-hostpath-provisioner"
            log "📁 Detected CRC environment, using storage class: ${storage_class}"
        # Check for AWS/EKS gp3
        elif oc get storageclass gp3-csi >/dev/null 2>&1; then
            storage_class="gp3-csi"
            log "☁️ Detected AWS environment, using storage class: ${storage_class}"
        # Check for default storage class
        else
            storage_class=$(oc get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}' | head -1)
            if [[ -n "$storage_class" ]]; then
                log "🔧 Using default storage class: ${storage_class}"
            else
                # Fallback to first available storage class
                storage_class=$(oc get storageclass -o jsonpath='{.items[0].metadata.name}')
                log "⚠️ No default storage class found, using: ${storage_class}"
            fi
        fi
    fi
    
    # Process template and apply
    if ! oc process -f "${TEMPLATE_FILE}" \
        -p STUDENT_NAME="${student_name}" \
        -p STUDENT_PASSWORD="${password}" \
        -p CLUSTER_DOMAIN="${CLUSTER_DOMAIN}" \
        -p STORAGE_CLASS="${storage_class}" \
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
    echo ""
    echo "📋 ${student_name} Access Information:"
    echo "   🌐 Code-Server: https://${route_url}"
    echo "   🔑 Code-Server Password: ${password}"
    if [[ "${CREATE_CONSOLE_USERS}" == "true" ]]; then
        echo "   🖥️  Console Login: oc login https://api.crc.testing:6443 -u ${student_name} -p ${CONSOLE_PASSWORD} --insecure-skip-tls-verify"
        echo "   🌍 OpenShift Console: https://console-openshift-console.${CLUSTER_DOMAIN}"
        echo "   🔐 Console Credentials: ${student_name} / ${CONSOLE_PASSWORD}"
    fi
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
CREATE_CONSOLE_USERS=false
CONSOLE_PASSWORD="workshop123"

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
        --console-access)
            CREATE_CONSOLE_USERS=true
            shift
            ;;
        --console-password)
            CONSOLE_PASSWORD="$2"
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
    echo "# Generated for ${#student_list[@]} students" >> "${CREDS_FILE}"
    echo "#" >> "${CREDS_FILE}"
    if [[ "${CREATE_CONSOLE_USERS}" == "true" ]]; then
        echo "# Format: Student | Code-Server URL | Code-Server Password | OpenShift Console | Console Password | CLI Login Command" >> "${CREDS_FILE}"
        echo "# OpenShift Console: https://console-openshift-console.${CLUSTER_DOMAIN}" >> "${CREDS_FILE}"
        echo "# Tekton Dashboard: https://tekton-dashboard.${CLUSTER_DOMAIN}" >> "${CREDS_FILE}"
    else
        echo "# Format: Student | Code-Server URL | Code-Server Password" >> "${CREDS_FILE}"
        echo "# Note: No OpenShift console access created (use --console-access flag)" >> "${CREDS_FILE}"
    fi
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
        if [[ "${CREATE_CONSOLE_USERS}" == "true" ]]; then
            echo "${student} | https://${route_url} | ${password} | https://console-openshift-console.${CLUSTER_DOMAIN} | ${CONSOLE_PASSWORD} | oc login https://api.crc.testing:6443 -u ${student} -p ${CONSOLE_PASSWORD} --insecure-skip-tls-verify" >> "${CREDS_FILE}"
        else
            echo "${student} | https://${route_url} | ${password}" >> "${CREDS_FILE}"
        fi
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
