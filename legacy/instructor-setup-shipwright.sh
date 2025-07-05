#!/bin/bash
# instructor-setup-shipwright.sh - Set up Shipwright ClusterBuildStrategy for IaC workshop

set -e

echo "🎓 Instructor Setup: Installing Shipwright ClusterBuildStrategy for IaC workshop"

# Check if running as cluster admin
if ! oc auth can-i create clusterbuildstrategies 2>/dev/null; then
    echo "❌ This script must be run by a cluster administrator"
    echo "💡 Please run as kubeadmin or user with cluster-admin role"
    exit 1
fi

echo "🔧 Installing buildah ClusterBuildStrategy..."

# Create the buildah ClusterBuildStrategy (similar to what java-webapp uses)
cat << 'EOF' | oc apply -f -
apiVersion: shipwright.io/v1beta1
kind: ClusterBuildStrategy
metadata:
  name: buildah
spec:
  parameters:
    - name: dockerfile
      description: Dockerfile path
      default: Dockerfile
      type: string
    - name: storage-driver
      description: Storage driver (vfs/overlay)
      default: vfs
      type: string
    - name: shp-output-image
      description: Fully qualified image name to push (injected automatically by Shipwright from Build.output.image)
      type: string
    - name: shp-source-root
      description: Source root directory (injected automatically by Shipwright)
      type: string
  buildSteps:
    - name: build-and-push
      image: quay.io/containers/buildah:v1.39.3
      workingDir: $(params.shp-source-root)
      securityContext:
        privileged: true
      command:
        - /bin/bash
      args:
        - -c
        - |
          set -e
          echo "🔍 Current directory: $(pwd)"
          echo "📁 Directory contents:"
          ls -la
          
          echo "🏗️ Building image with Dockerfile: $(params.dockerfile)"
          buildah --storage-driver=$(params.storage-driver) bud \
            -f $(params.dockerfile) \
            -t $(params.shp-output-image) \
            .
          
          echo "📤 Pushing image to registry..."
          buildah --storage-driver=$(params.storage-driver) push \
            $(params.shp-output-image) \
            docker://$(params.shp-output-image)
          
          echo "✅ Build and push completed successfully!"
EOF

# Verify the ClusterBuildStrategy was created
if oc get clusterbuildstrategy buildah >/dev/null 2>&1; then
    echo "✅ ClusterBuildStrategy 'buildah' installed successfully"
else
    echo "❌ Failed to install ClusterBuildStrategy 'buildah'"
    exit 1
fi

echo ""
echo "🎯 Shipwright setup complete!"
echo "📋 Students can now build their Node.js applications with:"
echo "   1. cd ~/workspace/labs/day1-pulumi"
echo "   2. git pull origin main"
echo "   3. pulumi up"
echo ""
echo "🔍 To verify builds are working:"
echo "   oc get buildruns -A | grep sample-form-app"
