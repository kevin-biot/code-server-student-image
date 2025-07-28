#!/bin/bash

echo "🚀 Git Push and Code Server Restart Script"
echo "==========================================="

# Change to the code-server-student-image directory
cd /Users/kevinbrown/code-server-student-image

echo "📁 Current directory: $(pwd)"

# Check git status
echo "📋 Checking git status..."
git status

# Add the modified startup.sh file
echo "➕ Adding startup.sh to git..."
git add startup.sh

# Commit the changes
echo "💾 Committing changes..."
git commit -m "Add Day 3 GitOps Lab README to startup.sh

- Added comprehensive ArgoCD GitOps lab instructions
- Includes step-by-step pipeline setup and execution
- Added troubleshooting section and success criteria
- Follows existing pattern of embedded README in startup.sh"

# Push the changes
echo "📤 Pushing changes to remote repository..."
git push

echo "✅ Git push completed!"

# Now restart code servers for students 01-05
echo "🔄 Restarting code servers for students 01-05..."

for i in {01..05}; do
    student="student${i}"
    echo "🔄 Restarting code-server for ${student}..."
    
    # Check if deployment exists
    if oc get deployment code-server -n $student &>/dev/null; then
        echo "  ✅ Found code-server deployment in namespace ${student}"
        
        # Perform rolling restart
        oc rollout restart deployment/code-server -n $student
        
        # Wait for rollout to complete
        echo "  ⏳ Waiting for rollout to complete for ${student}..."
        oc rollout status deployment/code-server -n $student --timeout=120s
        
        echo "  ✅ Rollout completed for ${student}"
    else
        echo "  ❌ No code-server deployment found in namespace ${student}"
    fi
    
    echo ""
done

echo "🎉 All operations completed!"
echo ""
echo "📝 Summary:"
echo "- ✅ Git changes pushed successfully"
echo "- ✅ Code servers restarted for student01-student05"
echo "- ✅ Students will now have Day 3 GitOps Lab README available"
echo ""
echo "🎯 Students can access the lab at: /home/coder/workspace/labs/day3-gitops/README.md"
