#!/usr/bin/env bash
set -euo pipefail

ARCH="${ARCH:-arm64}"
TKN_VERSION="${TKN_VERSION:-0.39.0}"
YQ_VERSION="${YQ_VERSION:-latest}"

TMPDIR="/tmp/preflight-checks-${ARCH}"
mkdir -p "$TMPDIR"
echo "🔍 Using temp directory: $TMPDIR"

# Helper to download and validate
check_binary() {
  local name="$1"
  local url="$2"
  local file="$TMPDIR/$(basename "$url")"

  echo -e "\n🔎 Checking $name:"
  echo "➡️  URL: $url"

  # Check URL reachable
  if ! curl -sI "$url" | grep -q "200 OK"; then
    echo "❌ ERROR: $name not reachable"
    return 1
  fi

  # Download
  echo "⬇️  Downloading..."
  if ! curl -L "$url" -o "$file"; then
    echo "❌ ERROR: Failed to download $name"
    return 1
  fi

  # Check format
  echo "🧪 File format:"
  file "$file"

  # If tar.gz, test unpack
  if [[ "$file" =~ \.tar\.gz$ ]]; then
    echo "📦 Testing tar extract..."
    if tar -tzf "$file" >/dev/null; then
      echo "✅ Tar archive valid"
    else
      echo "❌ ERROR: Invalid tar archive"
      return 1
    fi
  fi
}

echo "🔧 Preflight check for architecture: ${ARCH}"
echo "---------------------------------------------"

# Tekton CLI
check_binary "Tekton CLI" "https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tkn_${TKN_VERSION}_Linux_${ARCH}.tar.gz"

# yq
check_binary "yq" "https://github.com/mikefarah/yq/releases/${YQ_VERSION}/download/yq_linux_${ARCH}"

# kubectl
KUBECTL_RELEASE=$(curl -Ls https://dl.k8s.io/release/stable.txt)
check_binary "kubectl" "https://dl.k8s.io/release/${KUBECTL_RELEASE}/bin/linux/${ARCH}/kubectl"

# oc CLI
check_binary "oc CLI" "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/${ARCH}/openshift-client-linux.tar.gz"

# ArgoCD CLI
check_binary "ArgoCD CLI" "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${ARCH}"

# Helm (script only)
check_binary "Helm install script" "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"

# Pulumi (script only)
check_binary "Pulumi install script" "https://get.pulumi.com"

echo -e "\n✅ Preflight check complete. Clean up if needed:"
echo "  rm -rf $TMPDIR"
