#!/bin/bash
# instructor-setup-tekton-for-iac.sh - Setup Tekton ClusterTasks for IaC workshop

set -e

echo "🎓 Instructor Setup: Installing Tekton ClusterTasks for IaC workshop"

# Check if running as cluster admin
if ! oc auth can-i create clustertasks 2>/dev/null; then
    echo "❌ This script must be run by a cluster administrator"
    echo "💡 Please run as kubeadmin or user with cluster-admin role"
    exit 1
fi

echo "🔧 Installing ClusterTasks for Node.js IaC workshop..."

# 1. Install git-clone ClusterTask (if not already present)
if ! oc get clustertask git-clone >/dev/null 2>&1; then
    echo "📥 Installing git-clone ClusterTask..."
    oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.9/git-clone.yaml
else
    echo "✅ git-clone ClusterTask already exists"
fi

# 2. Install custom node-build ClusterTask
echo "📦 Installing node-build ClusterTask..."
cat << 'EOF' | oc apply -f -
apiVersion: tekton.dev/v1beta1
kind: ClusterTask
metadata:
  name: node-build
spec:
  description: Build Node.js application
  params:
    - name: source-dir
      description: Source directory
      default: "app"
      type: string
  workspaces:
    - name: source
      description: Source workspace
  steps:
    - name: build
      image: registry.redhat.io/ubi8/nodejs-18:latest
      workingDir: $(workspaces.source.path)/$(params.source-dir)
      script: |
        #!/bin/bash
        set -e
        echo "🔍 Current directory: $(pwd)"
        echo "📁 Directory contents:"
        ls -la
        
        if [[ -f package.json ]]; then
          echo "📦 Installing Node.js dependencies..."
          npm install --production
          echo "✅ Node.js build completed"
        else
          echo "❌ No package.json found"
          exit 1
        fi
EOF

# 3. Install shipwright-trigger ClusterTask with proper RBAC
echo "🏗️ Installing shipwright-trigger ClusterTask..."
cat << 'EOF' | oc apply -f -
apiVersion: tekton.dev/v1beta1
kind: ClusterTask
metadata:
  name: shipwright-trigger
spec:
  description: Trigger Shipwright build
  params:
    - name: BUILD_NAME
      description: Name of the Shipwright Build
      type: string
    - name: NAMESPACE
      description: Target namespace
      type: string
  steps:
    - name: trigger-build
      image: quay.io/openshift/origin-cli:latest
      script: |
        #!/bin/bash
        set -e
        
        BUILD_NAME="$(params.BUILD_NAME)"
        NAMESPACE="$(params.NAMESPACE)"
        BUILDRUN_NAME="${BUILD_NAME}-run-$(date +%s)"
        
        echo "🚀 Creating BuildRun: $BUILDRUN_NAME"
        
        cat << BUILDRUN_EOF | oc apply -f -
        apiVersion: shipwright.io/v1beta1
        kind: BuildRun
        metadata:
          name: $BUILDRUN_NAME
          namespace: $NAMESPACE
        spec:
          build:
            name: $BUILD_NAME
        BUILDRUN_EOF
        
        echo "⏳ Waiting for BuildRun to complete..."
        oc wait --for=condition=Succeeded=true buildrun/$BUILDRUN_NAME -n $NAMESPACE --timeout=10m
        
        echo "✅ BuildRun completed successfully"
EOF

# 4. Install deploy-app ClusterTask
echo "🚀 Installing deploy-app ClusterTask..."
cat << 'EOF' | oc apply -f -
apiVersion: tekton.dev/v1beta1
kind: ClusterTask
metadata:
  name: deploy-app
spec:
  description: Deploy application to OpenShift
  params:
    - name: NAMESPACE
      description: Target namespace
      type: string
    - name: APP_NAME
      description: Application name
      type: string
      default: "web"
  steps:
    - name: restart-deployment
      image: quay.io/openshift/origin-cli:latest
      script: |
        #!/bin/bash
        set -e
        
        NAMESPACE="$(params.NAMESPACE)"
        APP_NAME="$(params.APP_NAME)"
        
        echo "🔄 Restarting deployment: $APP_NAME in namespace: $NAMESPACE"
        
        # Check if deployment exists
        if oc get deployment $APP_NAME -n $NAMESPACE >/dev/null 2>&1; then
          # Restart deployment to pick up new image
          oc rollout restart deployment/$APP_NAME -n $NAMESPACE
          oc rollout status deployment/$APP_NAME -n $NAMESPACE --timeout=300s
          echo "✅ Deployment restarted successfully"
        else
          echo "ℹ️ Deployment $APP_NAME not found - will be created by Pulumi"
        fi
EOF

# 5. Create RBAC for pipeline service accounts
echo "🔐 Setting up RBAC for pipeline service accounts..."
cat << 'EOF' | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tekton-iac-pipeline-role
rules:
- apiGroups: ["shipwright.io"]
  resources: ["builds", "buildruns"]
  verbs: ["get", "list", "create", "update", "patch", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "patch", "update"]
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["image.openshift.io"]
  resources: ["imagestreams", "imagestreamtags"]
  verbs: ["get", "list", "create", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tekton-iac-pipeline-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tekton-iac-pipeline-role
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: student01
- kind: ServiceAccount
  name: pipeline
  namespace: student02
- kind: ServiceAccount
  name: pipeline
  namespace: student03
- kind: ServiceAccount
  name: pipeline
  namespace: student04
- kind: ServiceAccount
  name: pipeline
  namespace: student05
# Add more student namespaces as needed
EOF

# 6. Ensure buildah ClusterBuildStrategy is properly configured
echo "🔨 Ensuring buildah ClusterBuildStrategy is configured..."
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

# Verify all ClusterTasks are installed
echo ""
echo "✅ Tekton ClusterTasks installation complete!"
echo ""
echo "📋 Installed ClusterTasks:"
oc get clustertask | grep -E "(git-clone|node-build|shipwright-trigger|deploy-app)" || echo "⚠️ Some ClusterTasks may not be listed above"

echo ""
echo "🎯 Setup complete!"
echo "📋 Students can now run their IaC workshop with:"
echo "   1. cd ~/workspace/labs/day1-pulumi"
echo "   2. git pull origin main"
echo "   3. pulumi up"
echo ""
echo "🔍 To monitor pipeline execution:"
echo "   tkn pipelinerun list -A"
echo "   tkn pipelinerun logs <pipeline-run-name> -n <student-namespace> -f"
