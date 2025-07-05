#!/bin/bash
# phase1-technical-setup.sh - Prepare for core team technical validation

set -e

echo "🔧 Phase 1 Technical Validation Setup"
echo "======================================"

CLUSTER_DOMAIN="apps.bootcamp-ocs-cluster.bootcamp.tkmind.net"

echo "📦 Deploying 5 student environments for core team testing..."

# Deploy core testing environments
for i in {1..5}; do
    student_name=$(printf "student%02d" $i)
    echo "  Creating ${student_name} for technical validation..."
    
    oc process -f student-template.yaml \
        -p STUDENT_NAME="${student_name}" \
        -p CLUSTER_DOMAIN="${CLUSTER_DOMAIN}" \
        -p STORAGE_CLASS="gp3-csi" \
        | oc apply -f - > /dev/null
    
    sleep 3
done

echo ""
echo "⏳ Waiting for environments to be ready..."
sleep 60

echo ""
echo "📋 Core Team Access Information"
echo "==============================="

cat > phase1-access-info.txt << EOF
# Phase 1 Technical Validation Access
# Core Team: 2-3 Staff + Kevin
# Generated: $(date)

## Student Environment Assignments
EOF

for i in {1..5}; do
    student_name=$(printf "student%02d" $i)
    url="https://${student_name}-code-server.${CLUSTER_DOMAIN}"
    
    # Get password for each environment
    password=$(oc get secret -n ${student_name} -o jsonpath='{.data.password}' --ignore-not-found | base64 -d 2>/dev/null || echo "auto-generated")
    
    cat >> phase1-access-info.txt << EOF
### ${student_name}
- **URL**: ${url}
- **Password**: ${password}
- **Assigned to**: [Team Member Name]

EOF
done

cat >> phase1-access-info.txt << EOF

## Testing Focus by Session
### Session 1 (July 8): Day 1 Pulumi
- Test Pulumi CLI functionality
- AWS provider configuration
- Resource creation/destruction
- Document ALL issues encountered

### Session 2 (July 9): Day 2 Tekton  
- Test Tekton pipeline creation
- Git integration and webhooks
- Build and deploy workflows
- Performance under pipeline load

### Session 3 (July 10): Day 3 ArgoCD
- ArgoCD application management
- GitOps sync workflows
- Health monitoring and policies
- End-to-end integration validation

## Issue Documentation Template
For each issue found:
1. **Severity**: Critical/Major/Minor
2. **Component**: Pulumi/Tekton/ArgoCD/Infrastructure
3. **Description**: What went wrong
4. **Reproduction**: Steps to reproduce
5. **Workaround**: If available
6. **Priority**: Must-fix/Should-fix/Nice-to-have

## Contact Information
- **Primary Support**: Kevin Brown
- **Testing Coordinator**: [Manager Name]
- **Escalation Path**: [Add escalation contacts]
EOF

echo ""
echo "✅ Phase 1 technical validation environment ready!"
echo ""
echo "📄 Access information: phase1-access-info.txt"
echo ""
echo "🔍 Verify environment status:"
running_pods=$(oc get pods --all-namespaces | grep code-server | grep Running | wc -l || echo 0)
echo "   Running environments: ${running_pods}/5"

if [ "$running_pods" -eq "5" ]; then
    echo "   🎉 All environments ready for technical validation!"
else
    echo "   ⏳ Waiting for environments to start..."
    echo "   Check with: oc get pods --all-namespaces | grep student0[1-5]"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Share phase1-access-info.txt with core team"
echo "2. Schedule Session 1 (July 8, 4:00 PM KSA)"
echo "3. Prepare issue tracking spreadsheet"
echo "4. Set up daily progress check-ins"
