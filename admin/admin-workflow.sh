#!/bin/bash
# admin-workflow.sh - Unified entry point for admin operations
# Location: /admin/admin-workflow.sh
# Calls scripts in: deploy/, manage/, validate/ subdirectories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log() {
    echo -e "${GREEN}[ADMIN]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

case "${1:-help}" in
    "deploy")
        echo -e "${BLUE}Deploy Workflow${NC}"
        echo ""

        if [[ "$2" == "--profile" ]] && [[ -n "$3" ]]; then
            # Profile-based deployment (Kustomize)
            PROFILE="$3"
            START="${4:-1}"
            END="${5:-5}"
            log "Profile-based deployment: $PROFILE (students $START to $END)"
            "${SCRIPT_DIR}/deploy/deploy-profile.sh" \
                --profile "$PROFILE" \
                --start "$START" \
                --end "$END" \
                --domain "${CLUSTER_DOMAIN:?ERROR: CLUSTER_DOMAIN must be set}"
        elif [[ -n "$2" ]] && [[ -n "$3" ]]; then
            # Legacy template-based deployment
            log "Legacy deployment for students $2 to $3"
            "${SCRIPT_DIR}/deploy/complete-student-setup-simple.sh" "$2" "$3"
        else
            echo "Usage:"
            echo "  $0 deploy --profile <name> [start] [end]   # Profile-based (Kustomize)"
            echo "  $0 deploy [start] [end]                    # Legacy (OpenShift Template)"
            echo ""
            echo "Available profiles:"
            for d in "$REPO_ROOT"/deploy/overlays/*/; do
                [ -f "$d/kustomization.yaml" ] && echo "  - $(basename "$d")"
            done
            echo ""
            echo "Examples:"
            echo "  $0 deploy --profile devops-bootcamp 1 25"
            echo "  $0 deploy --profile java-dev 1 5"
            echo "  $0 deploy 1 25                              # Legacy mode"
        fi
        ;;

    "profiles")
        echo -e "${BLUE}Available Training Profiles${NC}"
        echo "=========================="
        echo ""
        for profile_dir in "$REPO_ROOT"/profiles/*/; do
            [ -f "$profile_dir/profile.yaml" ] || continue
            name=$(basename "$profile_dir")
            if command -v yq &>/dev/null; then
                desc=$(yq e '.metadata.description' "$profile_dir/profile.yaml" 2>/dev/null)
                version=$(yq e '.metadata.version' "$profile_dir/profile.yaml" 2>/dev/null)
                packs=$(yq e '.spec.toolPacks | join(", ")' "$profile_dir/profile.yaml" 2>/dev/null)
                echo -e "  ${GREEN}$name${NC} (v$version)"
                echo "    $desc"
                echo "    Tool packs: $packs"
            else
                echo -e "  ${GREEN}$name${NC}"
            fi
            # Check overlay exists
            if [ -d "$REPO_ROOT/deploy/overlays/$name" ]; then
                echo "    Overlay: deploy/overlays/$name/"
            else
                echo -e "    ${YELLOW}Overlay: not yet created${NC}"
            fi
            echo ""
        done
        ;;

    "validate")
        echo -e "${BLUE}Validation Workflow${NC}"
        echo ""

        case "${2:-help}" in
            "full")
                log "Running comprehensive validation suite"
                "${SCRIPT_DIR}/validate/comprehensive-validation.sh"
                ;;
            "quick")
                log "Running quick preflight checks"
                "${SCRIPT_DIR}/validate/preflight-checks.sh"
                ;;
            "e2e")
                log "Running end-to-end integration test"
                "${SCRIPT_DIR}/validate/end-to-end-test.sh"
                ;;
            "framework")
                log "Running codeserver test framework"
                "${SCRIPT_DIR}/validate/codeserver_test_framework.sh" auto
                ;;
            "profiles")
                log "Validating all training profiles"
                "${REPO_ROOT}/tests/test-profile.sh" ${3:-}
                ;;
            "lint")
                log "Running lint checks"
                "${REPO_ROOT}/tests/lint.sh"
                ;;
            *)
                echo "Usage: $0 validate [type]"
                echo ""
                echo "Types:"
                echo "  profiles     Validate profile YAML, content, kustomize overlays"
                echo "  lint         Shell syntax, YAML, secrets scan, Dockerfile checks"
                echo "  full         Comprehensive cluster validation suite"
                echo "  quick        Quick preflight checks"
                echo "  e2e          End-to-end integration test"
                echo "  framework    Codeserver test framework"
                ;;
        esac
        ;;

    "manage")
        echo -e "${BLUE}Management Workflow${NC}"
        echo ""

        case "${2:-help}" in
            "monitor")
                log "Monitoring student environments"
                "${SCRIPT_DIR}/manage/monitor-students.sh"
                ;;
            "teardown")
                if [[ -n "$3" ]] && [[ -n "$4" ]]; then
                    log "Tearing down students $3 to $4"
                    "${SCRIPT_DIR}/manage/teardown-students.sh" "$3" "$4"
                else
                    warn "This will cleanup student environments!"
                    log "For safety, running interactive teardown"
                    "${SCRIPT_DIR}/manage/teardown-students.sh"
                fi
                ;;
            "restart")
                log "Smart restart using enhanced batch processing"
                "${SCRIPT_DIR}/manage/restart-codeserver-enhanced.sh" "${3:-3}"
                ;;
            "restart-batch")
                if [[ -n "$3" ]]; then
                    log "Batch restart with custom size: $3"
                    "${SCRIPT_DIR}/manage/restart-codeserver-enhanced.sh" "$3"
                else
                    warn "Please provide batch size"
                    echo "Example: $0 manage restart-batch 5"
                fi
                ;;
            *)
                echo "Usage: $0 manage [operation]"
                echo ""
                echo "Operations:"
                echo "  monitor          Monitor cluster health"
                echo "  teardown [s] [e] Cleanup environments"
                echo "  restart          Smart restart (batch=3)"
                echo "  restart-batch N  Custom batch restart"
                ;;
        esac
        ;;

    "status")
        echo -e "${BLUE}Status Dashboard${NC}"
        echo "================"
        echo ""

        # Quick cluster info
        log "Cluster Status:"
        students=$(oc get namespaces -l student --no-headers 2>/dev/null | wc -l || echo "0")
        running_pods=$(oc get pods --all-namespaces -l app=code-server --no-headers 2>/dev/null | grep Running | wc -l || echo "0")
        echo "   Students deployed: $students"
        echo "   Running pods: $running_pods"
        echo ""

        # Show by profile
        log "By Profile:"
        for profile in devops-bootcamp java-dev cloud-native; do
            count=$(oc get pods --all-namespaces -l "profile=$profile" --no-headers 2>/dev/null | wc -l || echo "0")
            echo "   $profile: $count pods"
        done
        echo ""

        log "Quick Actions:"
        echo "   $0 validate profiles    # Validate profiles"
        echo "   $0 validate lint        # Run lint checks"
        echo "   $0 manage monitor       # Detailed monitoring"
        echo "   $0 profiles             # List available profiles"
        ;;

    "help"|*)
        echo -e "${BLUE}Admin Workflow${NC}"
        echo "=============="
        echo ""
        echo -e "${GREEN}Deployment:${NC}"
        echo "  $0 deploy --profile devops-bootcamp 1 25   # Profile-based (Kustomize)"
        echo "  $0 deploy --profile java-dev 1 5           # Smaller profile"
        echo "  $0 deploy 1 25                              # Legacy mode"
        echo ""
        echo -e "${GREEN}Profiles:${NC}"
        echo "  $0 profiles                                 # List available profiles"
        echo ""
        echo -e "${GREEN}Validation:${NC}"
        echo "  $0 validate profiles     # Validate profile definitions"
        echo "  $0 validate lint         # Shell, YAML, secrets, Dockerfile checks"
        echo "  $0 validate full         # Comprehensive cluster validation"
        echo "  $0 validate framework    # Codeserver test framework"
        echo ""
        echo -e "${GREEN}Management:${NC}"
        echo "  $0 manage monitor        # Monitor cluster health"
        echo "  $0 manage restart        # Smart restart"
        echo "  $0 manage teardown       # Cleanup environments"
        echo ""
        echo -e "${GREEN}Status:${NC}"
        echo "  $0 status                # Quick status dashboard"
        ;;
esac
