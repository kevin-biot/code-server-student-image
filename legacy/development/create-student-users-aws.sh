#!/bin/bash
# create-student-users-aws.sh - Create OpenShift users for students on AWS cluster

set -e

CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-apps.bootcamp-ocs-cluster.bootcamp.tkmind.net}"
START_NUM="${1:-1}"
END_NUM="${2:-25}"
DEFAULT_PASSWORD="${3:-DevOps2025}"

echo "🔐 Creating OpenShift Users for Students ${START_NUM} to ${END_NUM}"
echo "Cluster Domain: ${CLUSTER_DOMAIN}"
echo "Default Password: ${DEFAULT_PASSWORD}"
echo "=================================================="

# Create htpasswd file
HTPASSWD_FILE="/private/tmp/students.htpasswd"
rm -f "${HTPASSWD_FILE}"
touch "${HTPASSWD_FILE}"

create_student_user() {
    local student_num=$1
    local student_name=$(printf "student%02d" $student_num)
    local password="${DEFAULT_PASSWORD}"
    
    echo "🔑 Creating OpenShift user: ${student_name}"
    
    # Add to htpasswd file
    htpasswd -Bb "${HTPASSWD_FILE}" "${student_name}" "${password}"
    
    # Create user and identity objects
    oc create user "${student_name}" --dry-run=client -o yaml | oc apply -f - || true
    oc create identity htpasswd_provider:"${student_name}" --dry-run=client -o yaml | oc apply -f - || true
    oc create useridentitymapping htpasswd_provider:"${student_name}" "${student_name}" --dry-run=client -o yaml | oc apply -f - || true
    
    # Grant admin access to their namespace
    oc adm policy add-role-to-user admin "${student_name}" -n "${student_name}" || true
    
    # Grant view access to devops namespace (to see shared resources)
    oc adm policy add-role-to-user view "${student_name}" -n devops || true
    
    # Grant view access to openshift-gitops namespace (to see ArgoCD)
    oc adm policy add-role-to-user view "${student_name}" -n openshift-gitops || true
    
    echo "  ✅ ${student_name} created"
}

# Create all student users
for i in $(seq $START_NUM $END_NUM); do
    create_student_user $i
done

# Update OAuth configuration with htpasswd identity provider
echo ""
echo "🔧 Configuring htpasswd identity provider..."

# Create secret with htpasswd file
oc create secret generic htpass-secret \
    --from-file=htpasswd="${HTPASSWD_FILE}" \
    -n openshift-config \
    --dry-run=client -o yaml | oc apply -f -

# Update OAuth configuration
cat << EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpasswd_provider
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF

echo ""
echo "🎉 Student User Creation Complete!"
echo ""
echo "📋 Student Credentials:"
echo "========================"
for i in $(seq $START_NUM $END_NUM); do
    student_name=$(printf "student%02d" $i)
    echo "👤 ${student_name}:"
    echo "   Username: ${student_name}"
    echo "   Password: ${DEFAULT_PASSWORD}"
    echo "   Console: https://console-openshift-console.${CLUSTER_DOMAIN}"
    echo "   Code-Server: https://${student_name}-code-server.${CLUSTER_DOMAIN}"
    echo ""
done

echo "⚠️  Important Notes:"
echo "   - OAuth changes may take 2-3 minutes to take effect"
echo "   - Students should use both Console (for viewing) and Code-Server (for development)"
echo "   - Console login: ${DEFAULT_PASSWORD}"
echo "   - Code-Server login: Individual auto-generated passwords"

echo ""
echo "🔍 Verify OAuth pods restart:"
echo "   oc get pods -n openshift-authentication"

# Cleanup
rm -f "${HTPASSWD_FILE}"
