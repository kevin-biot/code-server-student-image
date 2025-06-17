#!/bin/bash
# build-and-verify.sh - Trigger a platform-aware Shipwright build and validate it

set -euo pipefail

echo "[INFO] Starting Darwin-based build verification"

# === Preflight CLI Checks ===
for cmd in oc kubectl tkn yq argocd pulumi; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[WARN] Required CLI '$cmd' is not found in PATH."
    else
        echo "[INFO] Found $cmd -> $($cmd --version 2>/dev/null | head -n 1)"
    fi
done

# === Set Variables ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="devops"

# === Apply Build Definitions ===
echo "[INFO] Applying Shipwright Build resources..."
oc apply -f "${SCRIPT_DIR}/shipwright/build.yaml"

# === Detect Architecture ===
ARCH=$(uname -m)
case "$ARCH" in
    arm64|aarch64)
        BUILD_ARCH="arm64"
        ;;
    x86_64)
        BUILD_ARCH="x86_64"
        ;;
    *)
        echo "[ERROR] Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "[INFO] Detected architecture: $BUILD_ARCH"

# === Trigger BuildRun ===
echo "[INFO] Starting BuildRun..."
buildrun_yaml=$(sed "s/ARCH_PLACEHOLDER/${BUILD_ARCH}/" "${SCRIPT_DIR}/shipwright/buildrun.yaml")
buildrun_name=$(echo "$buildrun_yaml" | oc create -f - -o name | cut -d/ -f2)

echo "[INFO] Waiting for BuildRun ${buildrun_name} to succeed..."
if ! oc wait --for=condition=Succeeded=true --timeout=10m "buildrun/${buildrun_name}" -n "$NAMESPACE"; then
    echo "[ERROR] BuildRun failed. Fetching diagnostics..."

    echo "--- DESCRIBE BUILD ---"
    oc describe buildrun/"${buildrun_name}" -n "$NAMESPACE" || true

    echo "--- BUILD YAML ---"
    oc get buildrun/"${buildrun_name}" -n "$NAMESPACE" -o yaml || true

    echo "--- BUILD LOGS ---"
    oc logs buildrun/"${buildrun_name}" -n "$NAMESPACE" || true

    exit 1
fi

# === Validate ImageTag ===
echo "[INFO] Verifying image stream tag 'code-server-student:latest'..."
if oc get istag code-server-student:latest -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "[SUCCESS] Image stream tag exists and build succeeded."
else
    echo "[ERROR] Image stream tag 'code-server-student:latest' not found." >&2
    exit 1
fi

echo "[DONE] Build and validation complete for ARCH=${BUILD_ARCH}"
