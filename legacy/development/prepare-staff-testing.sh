#!/bin/bash
# prepare-staff-testing.sh - Set up environment for internal staff testing

set -e

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
TOTAL_STUDENTS="${1:-20}"

echo "🧪 Preparing Staff Testing Environment"
echo "====================================="
echo "Cluster Domain: ${CLUSTER_DOMAIN}"
echo "Student Instances: 1-${TOTAL_STUDENTS}"
echo ""

# Create student environments for staff testing
echo "📦 Deploying ${TOTAL_STUDENTS} student environments..."
for i in $(seq 1 $TOTAL_STUDENTS); do
    student_name=$(printf "student%02d" $i)
    
    echo "  Creating ${student_name}..."
    oc process -f student-template.yaml \
        -p STUDENT_NAME="${student_name}" \
        -p CLUSTER_DOMAIN="${CLUSTER_DOMAIN}" \
        -p STORAGE_CLASS="gp3-csi" \
        | oc apply -f - > /dev/null
    
    # Small delay to avoid overwhelming API server
    sleep 2
done

echo ""
echo "⏳ Waiting for deployments to become ready..."
sleep 30

# Generate staff access information
echo ""
echo "📋 Staff Testing Access Information"
echo "=================================="

cat > staff-access-info.txt << EOF
# Staff Testing Access Information
# Generated: $(date)

## Code-Server Access URLs

### Group A - Day 1 Pulumi Testing (student01-05)
EOF

for i in {1..5}; do
    student_name=$(printf "student%02d" $i)
    url="https://${student_name}-code-server.${CLUSTER_DOMAIN}"
    echo "- ${student_name}: ${url}" >> staff-access-info.txt
done

cat >> staff-access-info.txt << EOF

### Group B - Day 2 Tekton Testing (student06-10)
EOF

for i in {6..10}; do
    student_name=$(printf "student%02d" $i)
    url="https://${student_name}-code-server.${CLUSTER_DOMAIN}"
    echo "- ${student_name}: ${url}" >> staff-access-info.txt
done

cat >> staff-access-info.txt << EOF

### Group C - Day 3 ArgoCD Testing (student11-15)
EOF

for i in {11..15}; do
    student_name=$(printf "student%02d" $i)
    url="https://${student_name}-code-server.${CLUSTER_DOMAIN}"
    echo "- ${student_name}: ${url}" >> staff-access-info.txt
done

cat >> staff-access-info.txt << EOF

### Group D - End-to-End Testing (student16-20)
EOF

for i in {16..20}; do
    student_name=$(printf "student%02d" $i)
    url="https://${student_name}-code-server.${CLUSTER_DOMAIN}"
    echo "- ${student_name}: ${url}" >> staff-access-info.txt
done

cat >> staff-access-info.txt << EOF

## Login Information
- **Username:** Each student environment uses code-server web interface
- **Password:** Check individual student passwords with:
  \`oc get secret -n studentXX code-server-secret -o jsonpath='{.data.password}' | base64 -d\`

## Testing Guidelines
1. **Use only assigned student instances** for your group
2. **Follow exercise instructions** step-by-step
3. **Document any issues** encountered
4. **Note performance/timing** observations
5. **Test concurrent access** where applicable

## Admin Access
- Cluster Console: https://console-openshift-console.${CLUSTER_DOMAIN}
- ArgoCD: https://openshift-gitops-server-openshift-gitops.${CLUSTER_DOMAIN}

## Support During Testing
- Primary: Kevin Brown
- Backup: [Add backup contacts]
- Escalation: [Add escalation path]
EOF

echo ""
echo "✅ Staff testing environment prepared!"
echo ""
echo "📄 Access information saved to: staff-access-info.txt"
echo ""
echo "🔍 Verify deployments:"
echo "   oc get pods --all-namespaces | grep code-server | grep Running | wc -l"
echo "   Expected: ${TOTAL_STUDENTS} running pods"
echo ""
echo "📊 Monitor during testing:"
echo "   watch 'oc top nodes && echo && oc get pods --all-namespaces | grep student | grep -v Running'"

# Check deployment status
echo ""
echo "📈 Current Deployment Status:"
running_pods=$(oc get pods --all-namespaces | grep code-server | grep Running | wc -l || echo 0)
total_pods=$(oc get pods --all-namespaces | grep code-server | wc -l || echo 0)
echo "   Running: ${running_pods}/${total_pods} code-server pods"

if [ "$running_pods" -eq "$TOTAL_STUDENTS" ]; then
    echo "   🎉 All student environments ready for testing!"
else
    echo "   ⏳ Some environments still starting up..."
    echo "   📝 Check status with: oc get pods --all-namespaces | grep student"
fi

# Display access info
echo ""
echo "📋 Quick Access Summary:"
cat staff-access-info.txt | grep "^- student" | head -5
echo "   (See staff-access-info.txt for complete list)"
