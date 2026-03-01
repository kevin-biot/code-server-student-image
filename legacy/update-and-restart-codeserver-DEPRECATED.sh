#!/bin/bash
# ------------------------------------------------------------------
# DEPRECATED SCRIPT - DO NOT USE
# ------------------------------------------------------------------
# This script has been DEPRECATED and moved to legacy/
# 
# PROBLEMS WITH THIS SCRIPT:
# - Combines build + restart operations (violates separation of concerns)
# - No batch processing for large deployments (37+ servers fail)
# - No PVC lock detection/cleanup (ghost node issues)
# - No proper image pull policy (cache issues)
# - Missing production safety features
#
# REPLACEMENTS:
# 1. Build Phase: use build-and-verify.sh (separate step)
# 2. Restart Phase: ./admin-workflow.sh manage restart
#    (uses restart-codeserver-enhanced.sh with all production fixes)
#
# DO NOT USE THIS SCRIPT IN PRODUCTION!
# ------------------------------------------------------------------

echo "❌ DEPRECATED SCRIPT - DO NOT USE!"
echo ""
echo "This script has been deprecated due to production issues:"
echo "• No batch processing (fails with 37+ servers)"
echo "• No PVC lock detection (ghost node issues)"
echo "• Mixes build + restart operations"
echo ""
echo "✅ Use instead:"
echo "   1. Build: ./build-and-verify.sh"
echo "   2. Restart: ./admin/admin-workflow.sh manage restart"
echo ""
exit 1

# ------------------------------------------------------------------
# Rebuild code-server image and restart existing deployments
# This preserves passwords and other configurations while updating
# the image with the new README file
# ------------------------------------------------------------------

set -euo pipefail

echo "🔧 Code-Server Image Update and Restart Script"
echo "This will rebuild the code-server image with the new README and restart existing deployments"
echo

# Check if required files exist (relative to repository root)
if [[ ! -f "../../Dockerfile" ]] || [[ ! -f "../../day2-tekton-README.md" ]]; then
    echo "❌ Error: Required files not found"
    echo "   Expected files: ../../Dockerfile, ../../day2-tekton-README.md"
    echo "   Run this script from admin/manage/ or ensure repository structure is correct"
    exit 1
fi

# Get current image info
IMAGE_NAME="code-server-student"
BUILD_TAG="latest"
REGISTRY_PREFIX="${REGISTRY_PREFIX:-}"

if [[ -n "$REGISTRY_PREFIX" ]]; then
    FULL_IMAGE_NAME="$REGISTRY_PREFIX/$IMAGE_NAME:$BUILD_TAG"
else
    FULL_IMAGE_NAME="$IMAGE_NAME:$BUILD_TAG"
fi

echo "📋 Configuration:"
echo "   🏷️  Image Name: $FULL_IMAGE_NAME"
echo "   📂 README Source: day2-tekton-README.md"
echo "   📁 Target Path: /home/coder/workspace/labs/day2-tekton/README.md"
echo

read -rp "❓ Proceed with image rebuild and deployment restart? (y/n): " CONFIRM
[[ "$CONFIRM" != [yY] ]] && { echo "❌ Aborted."; exit 1; }

echo
echo "🏗️  Step 1: Building new code-server image..."
echo "⏱️  This may take several minutes..."

# Change to repository root for building
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
echo "Building from: $(pwd)"

# Build the image
if command -v podman &> /dev/null; then
    echo "Using podman for build..."
    podman build -t "$FULL_IMAGE_NAME" . || {
        echo "❌ Build failed with podman"
        exit 1
    }
elif command -v docker &> /dev/null; then
    echo "Using docker for build..."
    docker build -t "$FULL_IMAGE_NAME" . || {
        echo "❌ Build failed with docker"
        exit 1
    }
else
    echo "❌ Neither podman nor docker found. Please install one of them."
    exit 1
fi

echo "✅ Image build completed successfully"

# Push image if registry prefix is specified
if [[ -n "$REGISTRY_PREFIX" ]]; then
    echo
    echo "🚀 Step 2: Pushing image to registry..."
    
    if command -v podman &> /dev/null; then
        podman push "$FULL_IMAGE_NAME" || {
            echo "❌ Push failed with podman"
            exit 1
        }
    else
        docker push "$FULL_IMAGE_NAME" || {
            echo "❌ Push failed with docker"
            exit 1
        }
    fi
    echo "✅ Image pushed successfully"
fi

echo
echo "🔄 Step 3: Finding and restarting code-server deployments..."

# Find all code-server deployments
DEPLOYMENTS=$(oc get deployments -A -l app=code-server -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' 2>/dev/null || echo "")

if [[ -z "$DEPLOYMENTS" ]]; then
    echo "❌ No code-server deployments found"
    echo "   Looking for deployments with label: app=code-server"
    echo "   Available deployments:"
    oc get deployments -A | grep -i code || echo "   No deployments found containing 'code'"
    exit 1
fi

echo "📋 Found code-server deployments:"
while IFS= read -r deployment; do
    if [[ -n "$deployment" ]]; then
        namespace=$(echo "$deployment" | cut -d'/' -f1)
        name=$(echo "$deployment" | cut -d'/' -f2)
        echo "   📦 $namespace/$name"
    fi
done <<< "$DEPLOYMENTS"

echo
echo "🔄 Restarting deployments to pick up new image..."

# Restart each deployment
RESTART_COUNT=0
while IFS= read -r deployment; do
    if [[ -n "$deployment" ]]; then
        namespace=$(echo "$deployment" | cut -d'/' -f1)
        name=$(echo "$deployment" | cut -d'/' -f2)
        
        echo "   ➡️  Restarting $namespace/$name"
        
        # Use rollout restart to trigger pod recreation
        if oc rollout restart deployment/"$name" -n "$namespace" >/dev/null 2>&1; then
            echo "   ✅ Restart triggered for $namespace/$name"
            ((RESTART_COUNT++))
        else
            echo "   ❌ Failed to restart $namespace/$name"
        fi
    fi
done <<< "$DEPLOYMENTS"

if [[ $RESTART_COUNT -gt 0 ]]; then
    echo
    echo "⏱️  Step 4: Waiting for deployments to complete rollout..."
    
    # Wait for rollouts to complete
    while IFS= read -r deployment; do
        if [[ -n "$deployment" ]]; then
            namespace=$(echo "$deployment" | cut -d'/' -f1)
            name=$(echo "$deployment" | cut -d'/' -f2)
            
            echo "   ⏳ Waiting for $namespace/$name to complete rollout..."
            if oc rollout status deployment/"$name" -n "$namespace" --timeout=300s >/dev/null 2>&1; then
                echo "   ✅ $namespace/$name rollout completed"
            else
                echo "   ⚠️  $namespace/$name rollout may still be in progress"
            fi
        fi
    done <<< "$DEPLOYMENTS"
fi

echo
echo "🎉 Update completed successfully!"
echo
echo "📋 Summary:"
echo "   ✅ Built new image: $FULL_IMAGE_NAME"
[[ -n "$REGISTRY_PREFIX" ]] && echo "   ✅ Pushed to registry: $REGISTRY_PREFIX"
echo "   ✅ Restarted $RESTART_COUNT code-server deployments"
echo "   📁 README now available at: /home/coder/workspace/labs/day2-tekton/README.md"

echo
echo "🔍 Verification commands:"
echo "   # Check deployment status:"
echo "   oc get deployments -A -l app=code-server"
echo
echo "   # Check specific student (replace student01 with actual namespace):"
echo "   oc get pods -n student01 -l app=code-server"
echo "   oc exec -it deployment/code-server -n student01 -- ls -la /home/coder/workspace/labs/day2-tekton/"
echo
echo "   # Test README accessibility:"
echo "   oc exec -it deployment/code-server -n student01 -- head -10 /home/coder/workspace/labs/day2-tekton/README.md"

echo
echo "ℹ️  Notes:"
echo "   - Passwords and other configurations are preserved"
echo "   - Students will see the new README when they navigate to ~/workspace/labs/day2-tekton/"
echo "   - The README is now available BEFORE they run git clone"
echo "   - All existing persistent data in student workspaces is preserved"
