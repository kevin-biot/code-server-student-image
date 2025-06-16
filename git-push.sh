#!/bin/bash
# git-push.sh - Helper script to commit and push changes

set -e

echo "=== Code Server Student Image - Git Push ==="
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
git commit -m "Major update: Enhanced multi-student code-server deployment

Features added:
- Enhanced Dockerfile with comprehensive development tools
- Template-based multi-student deployment system
- Automated deployment and monitoring scripts
- Security improvements (NetworkPolicy, ResourceQuota, RBAC)
- Resource management and student isolation
- Comprehensive documentation and quick start guide
- Makefile for easy operations
- Legacy files organized in separate directory

Tools included:
- Python 3, Node.js, Java 17
- Docker, kubectl, oc CLI, Helm
- VS Code extensions pre-installed
- Git configuration templates
- Startup scripts with welcome materials

Ready for production classroom deployment!"

echo
echo "Pushing to origin..."
git push origin main

echo
echo "✅ Successfully pushed all changes to GitHub!"
echo "Repository: https://github.com/kevin-biot/code-server-student-image"
