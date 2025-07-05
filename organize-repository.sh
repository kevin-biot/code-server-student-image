#!/bin/bash
# organize-repository.sh - Clean up repository structure

echo "🧹 Organizing Repository Structure"
echo "================================="

# Create additional legacy directories
mkdir -p legacy/testing
mkdir -p legacy/development
mkdir -p legacy/rbac-experiments

echo "📁 Moving legacy scripts..."

# Development/experimental scripts
mv preflight-tool-check-*.sh legacy/development/ 2>/dev/null || true
mv deploy-bulk-students-robust.sh legacy/development/ 2>/dev/null || true
mv complete-student-setup.sh legacy/development/ 2>/dev/null || true
mv create-student-users*.sh legacy/development/ 2>/dev/null || true
mv phase1-technical-setup.sh legacy/development/ 2>/dev/null || true
mv prepare-staff-testing.sh legacy/development/ 2>/dev/null || true

# RBAC experiments
mv argocd-rbac-addition.yaml legacy/rbac-experiments/ 2>/dev/null || true
mv argocd-serviceaccount-rbac.yaml legacy/rbac-experiments/ 2>/dev/null || true
mv openshift-gitops-rbac.yaml legacy/rbac-experiments/ 2>/dev/null || true

# Testing scripts
mv monitor-25-student-deployment.sh legacy/testing/ 2>/dev/null || true
mv quick-cluster-check.sh legacy/testing/ 2>/dev/null || true
mv cluster-capacity-check.sh legacy/testing/ 2>/dev/null || true
mv test-student-experience.sh legacy/testing/ 2>/dev/null || true
mv test-terminal-access.sh legacy/testing/ 2>/dev/null || true

# Planning documents
mv critical-path-plan.md legacy/ 2>/dev/null || true
mv staff-testing-*.md legacy/ 2>/dev/null || true
mv two-phase-testing-plan.md legacy/ 2>/dev/null || true

# Original/backup files
mv clone-workshop-repos-original.sh legacy/ 2>/dev/null || true
mv startup-original.sh legacy/ 2>/dev/null || true
mv code-server-deployment.yaml legacy/ 2>/dev/null || true

# Infrastructure setup (use if needed)
mv install-workshop-infrastructure.sh legacy/ 2>/dev/null || true
mv instructor-setup-*.sh legacy/ 2>/dev/null || true

echo "✅ Repository organized!"
echo ""
echo "📋 Production Scripts (in root):"
ls -1 *.sh | head -10
echo ""
echo "📁 Legacy Scripts (in legacy/):"
ls -1 legacy/ | head -10
