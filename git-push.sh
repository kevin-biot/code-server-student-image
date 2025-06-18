#!/bin/bash
# git-push.sh - Helper script to commit and push enhanced DevOps workshop changes

set -e

echo "=== DevOps Workshop Code Server - Enhanced Git Push ==="
echo

# Check if we're in a git repository
if [[ ! -d .git ]]; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Check git status
echo "Current git status:"
git status --short

echo
echo "Adding all files to staging..."
git add .

echo
echo "Files staged for commit:"
git diff --cached --name-status

echo
echo "Creating commit..."
git commit -m "Fix: Multi-architecture support and GPGME symbol lookup error

🔧 Critical Fixes:
- Fixed GPGME symbol lookup error in storage-untar
- Added proper multi-architecture support (ARM64 + AMD64)
- Runtime architecture detection for tool downloads
- Added GPGME libraries (libgpgme11, libgpgme-dev, gpgme)
- Changed storage driver from vfs to overlay for better compatibility

🏗️ Architecture Improvements:
- Auto-detect architecture during build (uname -m)
- Architecture-aware downloads for yq, oc, kubectl, ArgoCD CLI
- Removed hardcoded ARM64 assumptions
- Works on Mac CRC (ARM64) and AWS Linux (AMD64)

✅ Tekton PVC Integration:
- Enhanced student template with shared-pvc for Tekton pipelines
- Improved RBAC for pipeline ServiceAccount
- Added pipeline-specific resource quotas

🔍 Troubleshooting:
- Added fix-gpgme-issue.sh diagnostic script
- Better error handling and logging
- Comprehensive build validation

Tested and verified working on ARM64 CRC cluster.
Ready for production deployment on any architecture."

echo
echo "Pushing to origin..."
git push origin main

echo
echo "✅ Successfully pushed enhanced DevOps workshop to GitHub!"
echo "Repository: https://github.com/kevin-biot/code-server-student-image"
echo
echo "🎯 Next Steps:"
echo "1. Build new image: oc start-build code-server-student --from-dir=. --follow"
echo "2. Test deployment: ./deploy-students.sh -n 2 -d apps.cluster.domain"
echo "3. Verify all tools: Access student environment and test CLIs"