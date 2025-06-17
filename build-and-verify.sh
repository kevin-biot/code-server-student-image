#!/bin/bash
# build-and-verify.sh - Build the code-server image and verify the output image stream

set -e

# Verify required commands are available
if ! command -v oc >/dev/null 2>&1; then
    echo "Error: required command 'oc' not found in PATH." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Apply Shipwright build configuration
echo "[INFO] Applying Shipwright configuration..."
oc apply -f "${SCRIPT_DIR}/shipwright/"

# Start the build and capture the buildrun name
echo "[INFO] Starting build..."
buildrun_full=$(oc create -f "${SCRIPT_DIR}/shipwright/buildrun.yaml" -o name)
buildrun_name=${buildrun_full#*/}

echo "[INFO] Waiting for buildrun ${buildrun_name} to succeed..."
if ! oc wait --for=condition=Succeeded=true --timeout=10m "buildrun/${buildrun_name}" -n devops; then
    echo "[ERROR] Build failed. Fetching logs..."
    oc logs "buildrun/${buildrun_name}" -n devops || true
    exit 1
fi

# Verify the image exists
if oc get istag code-server-student:latest -n devops >/dev/null 2>&1; then
    echo "[INFO] Build completed successfully and image tag exists."
else
    echo "[ERROR] Image tag code-server-student:latest not found in devops namespace." >&2
    exit 1
fi
