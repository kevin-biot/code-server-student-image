#!/bin/bash
# create-student-users.sh - Create OpenShift users for students

set -e

create_student_user() {
    local student_name=$1
    local password=$2
    
    echo "Creating OpenShift user: ${student_name}"
    
    # Create user in htpasswd format
    htpasswd -Bb /tmp/users.htpasswd "${student_name}" "${password}"
    
    # Create user and identity objects
    oc create user "${student_name}" || true
    oc create identity htpasswd_provider:"${student_name}" || true
    oc create useridentitymapping htpasswd_provider:"${student_name}" "${student_name}" || true
    
    # Grant access to their namespace
    oc adm policy add-role-to-user admin "${student_name}" -n "${student_name}"
    
    echo "  Username: ${student_name}"
    echo "  Password: ${password}"
    echo "  Console: https://console-openshift-console.apps-crc.testing"
    echo ""
}

# Example usage
# create_student_user "alice" "workshop123"
# create_student_user "bob" "workshop123"
# create_student_user "charlie" "workshop123"

echo "Student OpenShift users created!"
echo "Students can now login to:"
echo "  - OpenShift Console: https://console-openshift-console.apps-crc.testing"
echo "  - Tekton Dashboard: https://tekton-dashboard.apps-crc.testing"
