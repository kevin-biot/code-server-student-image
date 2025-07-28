#!/bin/bash
# Simple git push for workshop optimizations

set -e

echo "🚀 Pushing Workshop Optimizations"
echo "================================="

# 1. Push code-server template changes
echo ""
echo "📝 Pushing code-server template optimizations..."
cd /Users/kevinbrown/code-server-student-image

if [[ -n $(git status --porcelain) ]]; then
    git add student-template.yaml
    git commit -m "Optimize code-server resources: 400m CPU, 600Mi memory"
    git push origin main
    echo "✅ Code-server template pushed"
else
    echo "ℹ️  No changes in code-server repo"
fi

# 2. Push Tekton task changes  
echo ""
echo "⚙️ Pushing Tekton task optimizations..."
cd /Users/kevinbrown/devops-test/java-webapp

if [[ -n $(git status --porcelain) ]]; then
    git add tekton/clustertasks/
    git commit -m "Optimize Tekton task resources for 25 concurrent pipelines"
    git push origin dev
    echo "✅ Tekton tasks pushed to dev branch"
else
    echo "ℹ️  No changes in java-webapp repo"
fi

# 3. Apply Tekton changes to cluster
echo ""
echo "🔧 Applying Tekton changes to cluster..."
cd /Users/kevinbrown/devops-test/java-webapp
oc apply -f tekton/clustertasks/git-clone.yaml
oc apply -f tekton/clustertasks/maven-build.yaml  
oc apply -f tekton/clustertasks/war-sanity-check.yaml
echo "✅ ClusterTasks updated"

# 4. Update template in cluster
echo ""
echo "📋 Updating student template in cluster..."
cd /Users/kevinbrown/code-server-student-image
oc apply -f student-template.yaml
echo "✅ Template updated"

echo ""
echo "✅ All optimizations pushed and applied!"
echo ""
echo "🎯 Next steps:"
echo "   1. Scale cluster to 10 nodes"
echo "   2. cd /Users/kevinbrown/code-server-student-image"
echo "   3. ./teardown-students.sh"
echo "   4. ./complete-student-setup-simple.sh 25"
echo "   5. Run load test"
