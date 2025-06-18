#!/bin/bash
# fix-gpgme-issue.sh - Diagnose and fix GPGME symbol lookup errors
set -euo pipefail

echo "🔍 Diagnosing GPGME symbol lookup error..."

# Function to check if we're in a build environment
check_build_env() {
    if [[ "${BUILD_CONTEXT:-}" == "shipwright" ]] || [[ "${BUILDAH_ISOLATION:-}" != "" ]]; then
        echo "📦 Running in Buildah/Shipwright build context"
        return 0
    fi
    return 1
}

# Function to fix GPGME in build environment
fix_gpgme_build() {
    echo "🔧 Installing GPGME libraries for build environment..."
    
    # Update package lists
    apt-get update
    
    # Install GPGME and related packages
    apt-get install -y \
        libgpgme11 \
        libgpgme-dev \
        gpgme \
        libassuan0 \
        libgpg-error0
    
    # Update library cache
    ldconfig
    
    echo "✅ GPGME libraries installed successfully"
}

# Function to fix GPGME in runtime environment
fix_gpgme_runtime() {
    echo "🔧 Checking GPGME runtime environment..."
    
    # Check if libraries exist
    if ldconfig -p | grep -q gpgme; then
        echo "✅ GPGME libraries found in system"
    else
        echo "❌ GPGME libraries not found"
        echo "Installing GPGME packages..."
        apt-get update && apt-get install -y libgpgme11 gpgme
    fi
    
    # Check for storage-untar binary issues
    if command -v storage-untar >/dev/null 2>&1; then
        echo "🔍 Found storage-untar binary"
        if ldd $(which storage-untar) 2>/dev/null | grep -q "not found"; then
            echo "❌ Missing dependencies for storage-untar:"
            ldd $(which storage-untar) | grep "not found" || true
        else
            echo "✅ storage-untar dependencies look good"
        fi
    fi
}

# Function to use alternative storage driver
use_alternative_storage() {
    echo "🔄 Switching to alternative storage configuration..."
    
    # Set environment variables for containers/storage
    export STORAGE_DRIVER="overlay"
    export STORAGE_OPTS="overlay.mountopt=nodev,metacopy=on"
    
    # Create containers storage config if it doesn't exist
    mkdir -p ~/.config/containers
    cat > ~/.config/containers/storage.conf << EOF
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"

[storage.options]
additionalimagestores = []

[storage.options.overlay]
mountopt = "nodev,metacopy=on"
EOF
    
    echo "✅ Alternative storage configuration applied"
}

# Main execution
main() {
    echo "🚀 Starting GPGME fix process..."
    
    # Check if we have root privileges
    if [[ $EUID -eq 0 ]]; then
        echo "✅ Running as root - can install packages"
        
        if check_build_env; then
            fix_gpgme_build
        else
            fix_gpgme_runtime
        fi
    else
        echo "⚠️  Not running as root - limited fixes available"
    fi
    
    # Always try the storage configuration fix
    use_alternative_storage
    
    echo "🎉 GPGME fix process completed!"
    echo ""
    echo "💡 If the issue persists, try:"
    echo "   1. Rebuild the image with the updated Dockerfile"
    echo "   2. Use 'overlay' storage driver instead of 'vfs'"
    echo "   3. Check OpenShift build logs for more details"
}

# Run the main function
main "$@"
