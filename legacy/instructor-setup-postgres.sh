#!/bin/bash
# instructor-setup-postgres.sh - Run this as cluster admin to enable PostgreSQL for students

set -e

echo "🎓 Instructor Setup: Enabling PostgreSQL for workshop students"

# Check if running as cluster admin
if ! oc auth can-i create clusterrolebindings 2>/dev/null; then
    echo "❌ This script must be run by a cluster administrator"
    echo "💡 Please run as kubeadmin or user with cluster-admin role"
    exit 1
fi

# Option 1: Grant anyuid to all student namespaces (easiest for workshop)
echo "🔧 Granting anyuid SCC to student namespaces..."

# Get all student namespaces
student_namespaces=$(oc get namespaces -l student -o name 2>/dev/null | sed 's/namespace\///' || true)

if [[ -z "$student_namespaces" ]]; then
    echo "⚠️  No student namespaces found with label 'student'"
    echo "💡 Manually specify student namespaces or ensure they're labeled correctly"
    
    # Fallback: grant for common student namespace pattern
    for i in {01..20}; do
        student_ns="student${i}"
        if oc get namespace "$student_ns" >/dev/null 2>&1; then
            echo "🔐 Granting anyuid to $student_ns..."
            oc adm policy add-scc-to-user anyuid -z default -n "$student_ns"
        fi
    done
else
    # Grant anyuid to found student namespaces
    for ns in $student_namespaces; do
        echo "🔐 Granting anyuid to $ns..."
        oc adm policy add-scc-to-user anyuid -z default -n "$ns"
    done
fi

echo ""
echo "✅ PostgreSQL permissions configured for workshop"
echo "📋 Students can now use standard PostgreSQL images"
echo ""
echo "🎯 Next steps for students:"
echo "   1. cd ~/workspace/labs/day1-pulumi"
echo "   2. git pull origin main"
echo "   3. pulumi up"

# Option 2: Create a custom SCC (more secure but complex)
echo ""
echo "🔐 Alternative: Creating workshop-postgres SCC for more security..."

cat << 'EOF' | oc apply -f -
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: workshop-postgres
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegedContainer: false
allowedCapabilities: []
defaultAddCapabilities: []
fsGroup:
  type: RunAsAny
readOnlyRootFilesystem: false
requiredDropCapabilities:
- ALL
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
supplementalGroups:
  type: RunAsAny
volumes:
- configMap
- downwardAPI
- emptyDir
- persistentVolumeClaim
- projected
- secret
EOF

echo "✅ Created workshop-postgres SCC"
echo "💡 To use custom SCC, students need: oc adm policy add-scc-to-user workshop-postgres -z default"
