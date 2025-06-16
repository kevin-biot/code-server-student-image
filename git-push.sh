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
git commit -m "Complete DevOps Workshop Enhancement: 3-Day Program Ready

🚀 MAJOR UPDATE: Full 3-Day DevOps Workshop Implementation

📅 Day 1: Infrastructure as Code with Pulumi
- Pulumi CLI and TypeScript support
- Microservices architecture provisioning
- Redis, web apps, workers, load generators
- Real-time visual feedback across 5 interfaces

🔄 Day 2: CI/CD Pipelines with Tekton
- Tekton CLI and pipeline orchestration
- Shipwright container builds
- Enterprise-grade automation
- Pipeline monitoring and debugging

🔄 Day 3: GitOps with ArgoCD (Ready)
- ArgoCD CLI integration
- GitOps workflow templates
- Application lifecycle management
- Automated sync and rollback

🛠️ Enhanced Toolchain:
- Comprehensive CLI tools: oc, kubectl, tkn, pulumi, argocd, helm, docker
- Multi-language support: Java 17, Node.js, Python 3, TypeScript
- Advanced VS Code extensions for DevOps workflows
- Shell completions and productivity features

🏗️ Infrastructure Improvements:
- Enhanced student template with proper resource quotas
- Improved RBAC for DevOps operations
- Network policies for security
- Persistent workspace with 5Gi storage
- Auto-detection of student namespaces

📚 Educational Features:
- Structured lab directories for 3 days
- Comprehensive README and quick start guides
- Example templates and references
- Progressive learning path from IaC → CI/CD → GitOps

🔒 Production Ready:
- Proper security contexts and non-root execution
- Resource limits and quotas
- Student isolation and namespace management
- Automated deployment and monitoring scripts

Ready for immediate classroom deployment!"

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