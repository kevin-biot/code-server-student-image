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
        echo -e "${BLUE}🚀 Admin Deployment Workflow${NC}"
        echo "Usage: $0 deploy [start_num] [end_num]"
        echo "  $0 deploy 1 25          # Deploy all 25 students (PRODUCTION)"
        echo "  $0 deploy 1 5           # Deploy first 5 students (TESTING)"
        echo ""
        
        if [[ -n "$2" ]] && [[ -n "$3" ]]; then
            log "Running complete student setup for students $2 to $3"
            echo "Calling: ${SCRIPT_DIR}/deploy/complete-student-setup-simple.sh $2 $3"
            "${SCRIPT_DIR}/deploy/complete-student-setup-simple.sh" "$2" "$3"
        else
            warn "Please provide start and end student numbers"
            echo "Example: $0 deploy 1 5"
        fi
        ;;
        
    "validate")
        echo -e "${BLUE}✅ Admin Validation Workflow${NC}"
        echo "Usage: $0 validate [test-type]"
        echo "  $0 validate full        # Run comprehensive validation suite"
        echo "  $0 validate quick       # Quick preflight checks"
        echo "  $0 validate e2e         # End-to-end integration test"
        echo "  $0 validate framework   # 518-test framework (codeserver)"
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
                log "Running codeserver test framework (518 tests)"
                "${SCRIPT_DIR}/validate/codeserver_test_framework.sh" auto
                ;;
            *)
                warn "Please specify validation type"
                echo "Available: full, quick, e2e, framework"
                ;;
        esac
        ;;
        
    "manage")
        echo -e "${BLUE}🔧 Admin Management Workflow${NC}"
        echo "Usage: $0 manage [operation] [args...]"
        echo "  $0 manage monitor       # Monitor student environments"
        echo "  $0 manage restart       # Smart restart (batch=3, fixes PVC/image issues)"
        echo "  $0 manage restart-batch 5  # Custom batch size restart"
        echo "  $0 manage teardown      # Cleanup environments (interactive)"
        echo "  $0 manage teardown 1 5  # Cleanup students 1-5"
        echo "  $0 manage scale 0       # Scale down all code-server pods"
        echo "  $0 manage scale 1       # Scale up all code-server pods"
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
                    warn "⚠️  This will cleanup student environments!"
                    log "For safety, running interactive teardown"
                    "${SCRIPT_DIR}/manage/teardown-students.sh"
                fi
                ;;
            "restart")
                log "Smart restart using enhanced batch processing (fixes PVC locks, image pulls)"
                "${SCRIPT_DIR}/manage/restart-codeserver-enhanced.sh" "${3:-3}"
                ;;
            "restart-batch")
                if [[ -n "$3" ]]; then
                    log "Batch restart with custom size: $3 (addresses 37+ server issues)"
                    "${SCRIPT_DIR}/manage/restart-codeserver-enhanced.sh" "$3"
                else
                    warn "Please provide batch size"
                    echo "Example: $0 manage restart-batch 5"
                fi
                ;;
            "scale")
                if [[ -n "$3" ]]; then
                    log "Scaling code-server deployments to $3 replicas"
                    "${SCRIPT_DIR}/manage/scale.sh" "$3"
                else
                    warn "Please provide replica count (0 or 1)"
                    echo "Example: $0 manage scale 0"
                fi
                ;;
            *)
                warn "Please specify management operation"
                echo "Available: monitor, teardown, restart, restart-batch, scale"
                ;;
        esac
        ;;
        
    "status")
        echo -e "${BLUE}📊 Admin Status Dashboard${NC}"
        echo "=================================="
        echo ""
        
        # Quick cluster info
        log "Cluster Status:"
        students=$(oc get namespaces -l student --no-headers 2>/dev/null | wc -l || echo "0")
        running_pods=$(oc get pods --all-namespaces -l app=code-server --no-headers 2>/dev/null | grep Running | wc -l || echo "0")
        echo "   Students deployed: $students"
        echo "   Running pods: $running_pods"
        echo ""
        
        # Build system status
        log "Build System:"
        if oc get buildconfig code-server-student -n devops &>/dev/null; then
            echo "   ✅ Shipwright build config exists"
        else
            echo "   ⚠️  No build config found"
        fi
        echo ""
        
        log "Quick Actions:"
        echo "   $0 validate quick       # Quick health check"
        echo "   $0 manage monitor       # Detailed environment monitoring"
        echo "   $0 deploy 1 3          # Deploy test environment"
        ;;
        
    "help"|*)
        echo -e "${BLUE}👨‍💼 Admin Bootcamp Workflow${NC}"
        echo "=============================="
        echo ""
        echo -e "${GREEN}🚀 Deployment:${NC}"
        echo "  $0 deploy 1 25          # Deploy full bootcamp (25 students)"
        echo "  $0 deploy 1 5           # Deploy test environment (5 students)"
        echo ""
        echo -e "${GREEN}✅ Validation:${NC}"
        echo "  $0 validate full        # Comprehensive testing suite"
        echo "  $0 validate framework   # 518-test framework (production)"
        echo "  $0 validate quick       # Quick preflight checks"
        echo "  $0 validate e2e         # End-to-end integration test"
        echo ""
        echo -e "${GREEN}🔧 Management:${NC}"
        echo "  $0 manage monitor       # Monitor cluster health"
        echo "  $0 manage restart       # Smart restart (fixes PVC locks, image issues)"
        echo "  $0 manage restart-batch 5  # Custom batch restart (for 37+ servers)"
        echo "  $0 manage teardown      # Cleanup environments"
        echo "  $0 manage scale 0       # Scale down (maintenance)"
        echo "  $0 manage scale 1       # Scale up (operational)"
        echo ""
        echo -e "${GREEN}📊 Status:${NC}"
        echo "  $0 status              # Quick status dashboard"
        echo ""
        echo -e "${YELLOW}📚 Key Scripts:${NC}"
        echo "  Main Deploy: ./deploy/complete-student-setup-simple.sh"
        echo "  Monitoring:  ./manage/monitor-students.sh"
        echo "  Testing:     ./validate/codeserver_test_framework.sh"
        echo ""
        echo -e "${YELLOW}📖 Documentation:${NC}"
        echo "  Admin Guide: ./README.md"
        echo "  Deploy Guide: ./deploy/README.md"
        echo "  Validation: ./validate/README.md"
        ;;
esac
