#!/bin/bash
# Quick commit for template fix

cd /Users/kevinbrown/code-server-student-image

git add workshop-templates/day2-pipeline-run.yaml

git commit -m "fix: Update pipeline template for Tekton 1.19 compatibility

- Change apiVersion from tekton.dev/v1beta1 to tekton.dev/v1
- Add required apiVersion and kind fields to pipelineRef
- Ensures compatibility with OpenShift Pipelines 1.19

File: workshop-templates/day2-pipeline-run.yaml"

echo "✅ Template fix committed"
