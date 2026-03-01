#!/bin/bash
set -e
# generate-overlay.sh - Generate a per-student Kustomize overlay from a profile
#
# Usage:
#   ./deploy/generate-overlay.sh <profile-name> <student-name> <cluster-domain> [password]
#
# Example:
#   ./deploy/generate-overlay.sh devops-bootcamp student01 apps.cluster.example.com mypassword
#
# Generates: deploy/generated/<student-name>/kustomization.yaml
# Apply with: oc apply -k deploy/generated/<student-name>/

PROFILE_NAME="${1:?Usage: $0 <profile-name> <student-name> <cluster-domain> [password]}"
STUDENT_NAME="${2:?Usage: $0 <profile-name> <student-name> <cluster-domain> [password]}"
CLUSTER_DOMAIN="${3:?Usage: $0 <profile-name> <student-name> <cluster-domain> [password]}"
STUDENT_PASSWORD="${4:-${SHARED_PASSWORD:-changeme}}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OVERLAY_SRC="$SCRIPT_DIR/overlays/$PROFILE_NAME"
OUTPUT_DIR="$SCRIPT_DIR/generated/$STUDENT_NAME"

# Validate profile overlay exists
if [ ! -d "$OVERLAY_SRC" ]; then
    echo "ERROR: Profile overlay not found: $OVERLAY_SRC"
    echo "Available profiles:"
    ls -1 "$SCRIPT_DIR/overlays/" 2>/dev/null || echo "  (none)"
    exit 1
fi

echo "Generating overlay for $STUDENT_NAME (profile: $PROFILE_NAME)..."

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Copy the profile overlay as the base
cp -a "$OVERLAY_SRC"/* "$OUTPUT_DIR/"

# Apply student-specific substitutions across all YAML files
for f in "$OUTPUT_DIR"/*.yaml; do
    [ -f "$f" ] || continue
    sed -i.bak \
        -e "s/STUDENT_NAME/$STUDENT_NAME/g" \
        -e "s/STUDENT_PASSWORD/$STUDENT_PASSWORD/g" \
        -e "s/CLUSTER_DOMAIN/$CLUSTER_DOMAIN/g" \
        -e "s|ARGOCD_SERVER_URL|openshift-gitops-server-openshift-gitops.$CLUSTER_DOMAIN|g" \
        "$f"
    rm -f "$f.bak"
done

# Fix the base reference to use absolute path from generated dir
sed -i.bak "s|../../base|$SCRIPT_DIR/base|g" "$OUTPUT_DIR/kustomization.yaml"
rm -f "$OUTPUT_DIR/kustomization.yaml.bak"

# Fix profile content/startup paths to absolute
sed -i.bak "s|\.\./\.\./\.\./profiles/|$REPO_ROOT/profiles/|g" "$OUTPUT_DIR/kustomization.yaml"
rm -f "$OUTPUT_DIR/kustomization.yaml.bak"

# Set namespace in kustomization
if ! grep -q "^namespace:" "$OUTPUT_DIR/kustomization.yaml"; then
    echo "" >> "$OUTPUT_DIR/kustomization.yaml"
    echo "namespace: $STUDENT_NAME" >> "$OUTPUT_DIR/kustomization.yaml"
fi

echo "Generated: $OUTPUT_DIR/"
echo "Apply with: oc apply -k $OUTPUT_DIR/"
