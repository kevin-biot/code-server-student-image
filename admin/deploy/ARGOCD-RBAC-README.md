# ArgoCD Student RBAC Configuration

This directory contains templates and scripts for configuring ArgoCD to allow students to login with their OpenShift credentials and view only their own applications.

## 🎯 Objective

Allow students to:
- Login to ArgoCD console using OpenShift SSO (student01, student02, etc.)
- Use their workshop password: `DevOps2025!`
- See only their own `java-webapp-studentXX` application
- Cannot see other students' applications

## 📁 Files

### `setup-argocd-student-rbac.sh`
**Purpose**: Automated script to configure ArgoCD RBAC for student access  
**Usage**: Run this script as cluster admin to set up student permissions  
**What it does**:
- Configures ArgoCD RBAC ConfigMap with student roles
- Maps OpenShift users (student01-student20) to student role  
- Sets application-specific permissions
- Restarts ArgoCD server to apply changes

### `argocd-student-rbac.yaml`
**Purpose**: Complete RBAC configuration template  
**Usage**: Reference for manual configuration or advanced customization  
**Contains**:
- Detailed RBAC policies
- OpenShift OAuth client configuration
- Service account token secrets

## 🚀 Quick Setup

### Prerequisites
- Cluster admin access
- OpenShift GitOps (ArgoCD) installed
- Student namespaces created (student01, student02, etc.)

### Installation Steps

1. **Run the setup script**:
   ```bash
   cd /Users/kevinbrown/code-server-student-image
   chmod +x setup-argocd-student-rbac.sh
   ./setup-argocd-student-rbac.sh
   ```

2. **Verify configuration**:
   ```bash
   oc get configmap argocd-rbac-cm -n openshift-gitops -o yaml
   ```

3. **Test student access**:
   - Open ArgoCD console: https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net
   - Click "LOG IN VIA OPENSHIFT"
   - Login as: student01 / DevOps2025!
   - Verify only java-webapp-student01 is visible

## 🔧 Configuration Details

### RBAC Policy Structure
```
# Student role permissions
p, role:student, applications, get, */*, allow
p, role:student, applications, sync, */*, allow
p, role:student, repositories, get, *, allow
p, role:student, clusters, get, *, allow

# User to role mapping
g, student01, role:student
g, student02, role:student
...

# Application-specific permissions
p, student01, applications, *, openshift-gitops/java-webapp-student01, allow
p, student02, applications, *, openshift-gitops/java-webapp-student02, allow
...
```

### Application Naming Convention
Students can only see applications matching the pattern:
- `java-webapp-student01` for student01
- `java-webapp-student02` for student02  
- etc.

Applications must be created in the `openshift-gitops` namespace.

## 🔍 Troubleshooting

### Student Can't Login
```bash
# Check OpenShift OAuth integration
oc get oauthclient argocd-server

# Check ArgoCD server status
oc get pods -n openshift-gitops | grep server
```

### Student Can't See Application
```bash
# Verify application exists
oc get application java-webapp-student01 -n openshift-gitops

# Check application labels/naming
oc get applications -n openshift-gitops --show-labels

# Verify RBAC policy
oc get configmap argocd-rbac-cm -n openshift-gitops -o jsonpath='{.data.policy\.csv}'
```

### Student Sees All Applications
```bash
# Check if RBAC policies are applied
oc logs deployment/openshift-gitops-server -n openshift-gitops | grep -i rbac

# Restart ArgoCD server
oc rollout restart deployment/openshift-gitops-server -n openshift-gitops
```

## 📚 Integration with Workshop

### Day 3 GitOps Setup Script
The ArgoCD setup script (`setup-student-pipeline.sh`) creates applications with the correct naming pattern:
```yaml
metadata:
  name: java-webapp-${NAMESPACE}
  namespace: openshift-gitops
```

This ensures student applications are visible to the correct users.

### Student Workflow
1. Complete Day 3 setup script (creates ArgoCD application)
2. Login to ArgoCD console with OpenShift credentials
3. View their application: java-webapp-studentXX
4. Monitor GitOps sync status and health

## 🎯 Success Criteria

After RBAC setup, students should be able to:
- ✅ Login to ArgoCD with student01/DevOps2025!
- ✅ See their java-webapp-studentXX application
- ✅ View application sync status and health
- ✅ NOT see other students' applications
- ✅ Sync/refresh their application if needed

## 🔄 Updates and Maintenance

### Adding New Students
Edit the RBAC script to include additional student IDs:
```bash
# Add to both sections:
g, student21, role:student
p, student21, applications, *, openshift-gitops/java-webapp-student21, allow
```

### Changing Application Names
Update the application-specific permissions to match your naming convention:
```bash
p, student01, applications, *, openshift-gitops/my-app-student01, allow
```

### Removing Student Access
Remove the user mapping and application permissions from the RBAC configuration.
