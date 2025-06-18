#!/bin/bash
# build-and-verify.sh - Build the code-server image via Shipwright and verify output
set -euo pipefail

echo "🔍 [INFO] Running preflight checks..."

# === Preflight Checks ===
REQUIRED_CMDS=(oc sed uname)
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "${cmd}" &>/dev/null; then
        echo "❌ [ERROR] Required command '${cmd}' not found in PATH."
        exit 1
    fi
done

if ! oc whoami &>/dev/null; then
    echo "❌ [ERROR] 'oc' is not logged in or cluster not reachable."
    exit 1
fi

if ! oc get namespace devops &>/dev/null; then
    echo "❌ [ERROR] Required namespace 'devops' not found."
    exit 1
fi

echo "✅ [INFO] Preflight checks passed."

# === Setup Variables ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TIMEOUT="${BUILD_TIMEOUT:-1200s}"  # 20 minutes default

# === Detect Architecture ===
detected_arch=$(uname -m)
case "${detected_arch}" in
    amd64|x86_64) build_arch="x86_64" ;;
    arm64|aarch64) build_arch="arm64" ;;
    *) echo "❌ [ERROR] Unsupported architecture: ${detected_arch}" >&2; exit 1 ;;
esac
echo "🖥️ [INFO] Detected architecture: ${detected_arch} → using build_arch: ${build_arch}"

# === Apply Shipwright Build ===
echo "📦 [INFO] Applying Shipwright Build definition..."
oc apply -f "${SCRIPT_DIR}/shipwright/build.yaml"

# === Start BuildRun ===
echo "🚀 [INFO] Creating BuildRun..."
buildrun_full=$(sed "s/ARCH_PLACEHOLDER/${build_arch}/" "${SCRIPT_DIR}/shipwright/buildrun.yaml" | oc create -f - -o name)
buildrun_name=${buildrun_full#*/}

echo "🔄 [INFO] BuildRun started: ${buildrun_name}"

# === Pod Discovery and Phase Monitor ===
echo "⏳ [INFO] Waiting for associated pod to be scheduled..."
for i in {1..20}; do
    pod_name=$(oc get pods -l buildrun="${buildrun_name}" -n devops -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
    [[ -n "$pod_name" ]] && break
    sleep 3
done

if [[ -n "${pod_name:-}" ]]; then
    echo "🔍 [INFO] Found pod: ${pod_name} - monitoring phase..."
    oc get pod "${pod_name}" -n devops -w --timeout=60s || true
else
    echo "⚠️  [WARN] No pod found yet for BuildRun '${buildrun_name}'."
fi

# === Wait for BuildRun Completion ===
echo "⏱️  [INFO] Waiting up to ${BUILD_TIMEOUT} for BuildRun to complete..."
if ! oc wait --for=condition=Succeeded=true --timeout="${BUILD_TIMEOUT}" "buildrun/${buildrun_name}" -n devops; then
    echo "❌ [ERROR] BuildRun ${buildrun_name} failed or timed out."

    echo "📋 [INFO] Attempting to get BuildRun logs..."
    oc logs "buildrun/${buildrun_name}" -n devops || echo "⚠️ No BuildRun logs available."

    echo "📋 [INFO] Attempting to get pod logs..."
    oc get pods -l buildrun="${buildrun_name}" -n devops -o name | while read -r pod; do
        echo "📄 Logs for ${pod}:"
        oc logs "${pod}" -n devops --all-containers=true || true
    done

    exit 1
fi

# === Verify Image Tag ===
if oc get istag code-server-student:latest -n devops &>/dev/null; then
    echo "✅ [SUCCESS] Build completed and image tag 'code-server-student:latest' exists in 'devops'."
else
    echo "❌ [ERROR] Image tag 'code-server-student:latest' not found in 'devops' namespace."
    exit 1
fi
