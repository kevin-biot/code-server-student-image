#!/usr/bin/env bash
set -euo pipefail

ARCH="${ARCH:-arm64}"
TKN_VERSION="${TKN_VERSION:-0.39.0}"
YQ_VERSION="${YQ_VERSION:-4.44.3}"

TMPDIR="/tmp/preflight-checks-${ARCH}"
mkdir -p "$TMPDIR"
echo "🔍 Using temp directory: $TMPDIR"

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
  
  if [[ "$HTTP_CODE" == "200" ]]; then
    echo "✅ URL is reachable (HTTP $HTTP_CODE)"
  elif [[ "$HTTP_CODE" == "302" ]] || [[ "$HTTP_CODE" == "301" ]]; then
    echo "✅ URL redirects (HTTP $HTTP_CODE) - following redirects"
  else
    echo "❌ ERROR: $name not reachable (HTTP $HTTP_CODE)"
    echo "   This might be due to:"
    echo "   - Network connectivity issues"
    echo "   - GitHub rate limiting"
    echo "   - Corporate firewall blocking GitHub releases"
    return 1
  fi

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
    head -n 5 "$file"
    return 1
  fi

  # Check format
  echo "🧪 File format:"
  file "$file" || echo "Unable to determine file type"

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

# Test with more specific Tekton CLI URL
echo "🔧 Testing Tekton CLI with specific version..."
check_binary "Tekton CLI" "https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tkn_${TKN_VERSION}_Linux_${ARCH}.tar.gz"

# yq with specific version
check_binary "yq" "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${ARCH}"

# kubectl
KUBECTL_RELEASE=$(curl -Ls https://dl.k8s.io/release/stable.txt 2>/dev/null || echo "v1.29.0")
echo "📥 Using kubectl version: $KUBECTL_RELEASE"
check_binary "kubectl" "https://dl.k8s.io/release/${KUBECTL_RELEASE}/bin/linux/${ARCH}/kubectl"

# oc CLI - try multiple sources
echo "🔧 Testing OpenShift CLI..."
if ! check_binary "oc CLI (latest)" "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/${ARCH}/openshift-client-linux.tar.gz"; then
    echo "⚠️  Latest OC failed, trying stable..."
    check_binary "oc CLI (stable)" "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/${ARCH}/openshift-client-linux.tar.gz"
fi

# ArgoCD CLI
check_binary "ArgoCD CLI" "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${ARCH}"

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
else
    echo "❌ Not connected to OpenShift cluster"
fi
