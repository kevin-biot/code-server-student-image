#!/bin/bash
# start-pipeline.sh - Interactive pipeline start

set -e

NAMESPACE=${STUDENT_NAMESPACE:-$(oc project -q)}

echo "🚀 Starting Java Web App Pipeline"
echo "Namespace: $NAMESPACE"

# Start pipeline interactively - tkn will prompt for any missing params
tkn pipeline start java-webapp-pipeline \
    --workspace name=source,claimName=shared-pvc \
    --param git-url=https://github.com/kevin-biot/devops-workshop.git \
    --param git-revision=main \
    --param build-name=java-webapp-build \
    --param namespace="$NAMESPACE" \
    --showlog
