#!/bin/bash
set -e
# deploy-profile.sh - Deploy students using Kustomize profile overlays
#
# Usage:
#   ./admin/deploy/deploy-profile.sh --profile devops-bootcamp --start 1 --end 25 --domain apps.example.com
#   ./admin/deploy/deploy-profile.sh -p java-dev -s 1 -e 5 -d apps.example.com
#
# Generates per-student Kustomize overlays and applies them to the cluster.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Defaults
PROFILE=""
START_NUM=1
END_NUM=5
CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-}"
BATCH_SIZE=5
DRY_RUN=false

usage() {
    echo "Usage: $0 --profile <name> --domain <domain> [options]"
    echo ""
    echo "Options:"
    echo "  -p, --profile    Profile name (required)"
    echo "  -d, --domain     Cluster domain (required, or set CLUSTER_DOMAIN env)"
    echo "  -s, --start      Start student number (default: 1)"
    echo "  -e, --end        End student number (default: 5)"
    echo "  -b, --batch      Batch size (default: 5)"
    echo "  --dry-run        Generate overlays but don't apply"
    echo ""
    echo "Available profiles:"
    for d in "$REPO_ROOT"/deploy/overlays/*/; do
        [ -f "$d/kustomization.yaml" ] && echo "  - $(basename "$d")"
    done
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--profile) PROFILE="$2"; shift 2 ;;
        -d|--domain) CLUSTER_DOMAIN="$2"; shift 2 ;;
        -s|--start) START_NUM="$2"; shift 2 ;;
        -e|--end) END_NUM="$2"; shift 2 ;;
        -b|--batch) BATCH_SIZE="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[ -z "$PROFILE" ] && { echo "ERROR: --profile is required"; usage; }
[ -z "$CLUSTER_DOMAIN" ] && { echo "ERROR: --domain is required (or set CLUSTER_DOMAIN env)"; usage; }
[ ! -d "$REPO_ROOT/deploy/overlays/$PROFILE" ] && { echo "ERROR: Profile overlay not found: $PROFILE"; usage; }

SHARED_PASSWORD="${SHARED_PASSWORD:?ERROR: SHARED_PASSWORD must be set}"

echo "Deploying profile: $PROFILE"
echo "Students: $START_NUM to $END_NUM (batches of $BATCH_SIZE)"
echo "Cluster: $CLUSTER_DOMAIN"
echo "Dry run: $DRY_RUN"
echo "=================================="

current_batch=0
for i in $(seq "$START_NUM" "$END_NUM"); do
    student_name=$(printf "student%02d" "$i")

    echo ""
    echo "--- $student_name ---"

    # Generate overlay
    "$REPO_ROOT/deploy/generate-overlay.sh" "$PROFILE" "$student_name" "$CLUSTER_DOMAIN" "$SHARED_PASSWORD"

    generated_dir="$REPO_ROOT/deploy/generated/$student_name"

    if [ "$DRY_RUN" = true ]; then
        echo "  [dry-run] Would apply: kubectl apply -k $generated_dir"
        kubectl kustomize "$generated_dir" | grep "^kind:" | sort | uniq -c
    else
        echo "  Applying..."
        kubectl apply -k "$generated_dir" 2>&1 | sed 's/^/  /'
        echo "  Applied $student_name"
    fi

    ((current_batch++))

    # Batch pause
    if [ $((current_batch % BATCH_SIZE)) -eq 0 ] && [ "$i" -lt "$END_NUM" ]; then
        echo ""
        echo "Batch complete. Waiting 15s..."
        sleep 15
    fi
done

echo ""
echo "=================================="
if [ "$DRY_RUN" = true ]; then
    echo "Dry run complete. Generated overlays in deploy/generated/"
else
    echo "Deployed $((END_NUM - START_NUM + 1)) students with profile: $PROFILE"
    echo ""
    echo "Check status:"
    echo "  kubectl get pods -A -l profile=$PROFILE"
fi
