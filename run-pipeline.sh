#!/bin/bash
# run-pipeline.sh - Student-friendly pipeline execution

set -e

NAMESPACE=${STUDENT_NAMESPACE:-$(oc project -q)}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "🚀 Starting Java Web App Pipeline"
echo "Namespace: $NAMESPACE"
echo "Timestamp: $TIMESTAMP"

# Create pipeline run from template with direct substitution
cat << EOF | oc apply -f -
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: java-webapp-run-${TIMESTAMP}
  namespace: ${NAMESPACE}
spec:
  pipelineRef:
    name: java-webapp-pipeline
    apiVersion: tekton.dev/v1
    kind: Pipeline
  params:
    - name: git-url
      value: https://github.com/kevin-biot/devops-workshop.git
    - name: git-revision
      value: main
    - name: build-name
      value: java-webapp-build
    - name: namespace
      value: ${NAMESPACE}
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: shared-pvc
EOF

echo "✅ Pipeline started: java-webapp-run-$TIMESTAMP"
echo "📊 Follow logs with: tkn pipelinerun logs java-webapp-run-$TIMESTAMP -f"
echo "🌐 Or watch in console: https://console-openshift-console.apps-crc.testing"

# Automatically follow logs
echo "📋 Following pipeline logs..."
sleep 2
tkn pipelinerun logs "java-webapp-run-$TIMESTAMP" -f
