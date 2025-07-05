#!/usr/bin/env bash
set -euo pipefail

ARCH="${ARCH:-arm64}"
TKN_VERSION="${TKN_VERSION:-0.41.0}"  # Updated to latest version
YQ_VERSION="${YQ_VERSION:-4.44.3}"

# Architecture mapping for different tools
case "${ARCH}" in
    arm64) 
        TEKTON_ARCH="aarch64"  # Tekton uses aarch64 for ARM64
        YQ_ARCH="arm64"        # yq uses arm64
        KUBECTL_ARCH="arm64"   # kubectl uses arm64
        ARGOCD_ARCH="arm64"    # ArgoCD uses arm64
        ;;
    amd64|x86_64) 
        TEKTON_ARCH="x86_64"
        YQ_ARCH="amd64"
        KUBECTL_ARCH="amd64"
        ARGOCD_ARCH="amd64"
        ;;
    *) 
        echo "❌ Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

TMPDIR="/tmp/preflight-checks-${ARCH}"
mkdir -p "$TMPDIR"
echo "🔍 Using temp directory: $TMPDIR"
echo "🏗️  Architecture mapping: ${ARCH} → Tekton: ${TEKTON_ARCH}, Others: ${YQ_ARCH}"

# Helper to download and validate with better error handling
check_binary() {
  local name="$1"
  local url="$2"
  local file="$TMPDIR/$(basename "$url")"

  echo -e "\n🔎 Checking $name:"
  echo "➡️  URL: $url"

  # Check URL reachable with more specific error handling
  echo "🌐 Testing connectivity..."
  HTTP_CODE=$(curl -sL -w "%{http_code}" -o /dev/null "$url" --max-time 30 || echo "000")
  
  case "$HTTP_CODE" in
    200)
      echo "✅ URL is reachable (HTTP $HTTP_CODE)"
      ;;
    302|301)
      echo "✅ URL redirects (HTTP $HTTP_CODE) - following redirects"
      ;;
    404)
      echo "❌ ERROR: $name not found (HTTP 404)"
      echo "   The specific version/architecture combination may not exist."
      return 1
      ;;
    000)
      echo "❌ ERROR: Network connectivity issue"
      echo "   Could be DNS, firewall, or network timeout."
      return 1
      ;;
    *)
      echo "⚠️  WARNING: Unexpected HTTP code $HTTP_CODE"
      echo "   Proceeding with download attempt..."
      ;;
  esac

  # Download with redirect following
  echo "⬇️  Downloading..."
  if curl -L "$url" -o "$file" --max-time 60; then
    echo "✅ Download successful"
  else
    echo "❌ ERROR: Failed to download $name"
    return 1
  fi

  # Check file size
  FILE_SIZE=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
  if [[ "$FILE_SIZE" -lt 1000 ]]; then
    echo "❌ ERROR: Downloaded file too small ($FILE_SIZE bytes)"
    echo "   File contents:"
    head -n 5 "$file" 2>/dev/null || echo "   Cannot read file"
    return 1
  fi
  echo "📏 File size: $FILE_SIZE bytes"

  # Check format
  echo "🧪 File format:"
  file "$file" 2>/dev/null || echo "   Unable to determine file type"

  # If tar.gz, test unpack
  if [[ "$file" =~ \.tar\.gz$ ]]; then
    echo "📦 Testing tar extract..."
    if tar -tzf "$file" >/dev/null 2>&1; then
      echo "✅ Tar archive valid"
    else
      echo "❌ ERROR: Invalid tar archive"
      return 1
    fi
  fi
  
  echo "✅ $name check passed"
}

echo "🔧 Enhanced preflight check for architecture: ${ARCH}"
echo "Cluster: $(oc whoami --show-server 2>/dev/null || echo 'Not connected')"
echo "User: $(oc whoami 2>/dev/null || echo 'Not logged in')"
echo "---------------------------------------------"

# Tekton CLI with correct architecture mapping
echo "🔧 Testing Tekton CLI with corrected architecture mapping..."
check_binary "Tekton CLI" "https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tkn_${TKN_VERSION}_Linux_${TEKTON_ARCH}.tar.gz"

# yq with specific version
check_binary "yq" "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${YQ_ARCH}"

# kubectl
KUBECTL_RELEASE=$(curl -Ls https://dl.k8s.io/release/stable.txt 2>/dev/null || echo "v1.29.0")
echo "📥 Using kubectl version: $KUBECTL_RELEASE"
check_binary "kubectl" "https://dl.k8s.io/release/${KUBECTL_RELEASE}/bin/linux/${KUBECTL_ARCH}/kubectl"

# oc CLI - try multiple sources
echo "🔧 Testing OpenShift CLI..."
if ! check_binary "oc CLI (latest)" "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/${KUBECTL_ARCH}/openshift-client-linux.tar.gz"; then
    echo "⚠️  Latest OC failed, trying stable..."
    check_binary "oc CLI (stable)" "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/${KUBECTL_ARCH}/openshift-client-linux.tar.gz"
fi

# ArgoCD CLI
check_binary "ArgoCD CLI" "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${ARGOCD_ARCH}"

# Helm (script only)
check_binary "Helm install script" "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"

# Pulumi (script only)  
check_binary "Pulumi install script" "https://get.pulumi.com"

echo -e "\n✅ Enhanced preflight check complete!"
echo "📁 Downloaded files in: $TMPDIR"
echo "🧹 Clean up when done: rm -rf $TMPDIR"

# Additional checks for OpenShift environment
echo -e "\n🔍 OpenShift Environment Checks:"
if oc whoami >/dev/null 2>&1; then
    echo "✅ Connected to OpenShift cluster"
    echo "   User: $(oc whoami)"
    echo "   Server: $(oc whoami --show-server)"
    
    if oc get namespace devops >/dev/null 2>&1; then
        echo "✅ 'devops' namespace exists"
    else
        echo "⚠️  'devops' namespace not found - will need to create it"
    fi
    
    # Check if we can access the internal registry
    echo "🖼️  Testing registry access..."
    if oc get imagestream -n devops >/dev/null 2>&1; then
        echo "✅ Can access registry in devops namespace"
    else
        echo "⚠️  Cannot list imagestreams (may need permissions)"
    fi
else
    echo "❌ Not connected to OpenShift cluster"
fi

echo -e "\n📊 Summary:"
echo "   Architecture: ${ARCH} (Tekton: ${TEKTON_ARCH})"
echo "   Tekton CLI: v${TKN_VERSION}"
echo "   Downloads: Check individual results above"
echo ""
echo "🚀 Ready to proceed with build if all checks passed!"
