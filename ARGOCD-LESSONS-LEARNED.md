# ArgoCD RBAC Configuration - Lessons Learned

## 🎯 **FINAL WORKING SOLUTION**

**Method**: `defaultPolicy: "role:student"`  
**Result**: All authenticated users get student role automatically  
**Status**: ✅ VALIDATED WORKING

### **Complete Working Configuration**:
```yaml
spec:
  rbac:
    defaultPolicy: "role:student"
    policy: |
      # Admin access
      g, system:cluster-admins, role:admin
      g, cluster-admins, role:admin
      g, instructor, role:admin
      g, admin, role:admin
      
      # Student role permissions
      p, role:student, applications, *, */*, allow
      p, role:student, repositories, get, *, allow
      p, role:student, clusters, get, *, allow
    scopes: "[groups]"
```

## ❌ **What Doesn't Work**

### **Direct ConfigMap Updates**
```bash
# This gets overridden by the operator
oc patch configmap argocd-rbac-cm -n openshift-gitops ...
```
**Problem**: OpenShift GitOps operator manages the ConfigMap and resets it from the ArgoCD Custom Resource.

### **ClusterRoleBinding in Student Template**
```yaml
# This doesn't give ArgoCD console access
- apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding
  metadata:
    name: argocd-console-${STUDENT_NAME}
```
**Problem**: ArgoCD console access is controlled by ArgoCD's internal RBAC system, not Kubernetes RBAC.

## ✅ **What Actually Works**

### **ArgoCD Custom Resource Updates**
```bash
# This is persistent and operator-managed
oc patch argocd openshift-gitops -n openshift-gitops --type merge --patch '{
  "spec": {
    "rbac": {
      "defaultPolicy": "role:readonly",
      "policy": "g, student01, role:student\np, student01, applications, *, default/java-webapp-student01, allow",
      "scopes": "[groups]"
    }
  }
}'
```

## 🔧 **Correct Implementation**

### **For Future Deployments**

1. **Use `configure-argocd-rbac.sh` script** - Updates ArgoCD Custom Resource
2. **Run AFTER student deployment** - When you know student count
3. **No ConfigMap updates** - Let operator manage the ConfigMap
4. **No student template RBAC** - ArgoCD console access is centrally managed

### **Required Permissions for Students**
```
# Group assignment
g, student01, role:student

# Application permissions  
p, student01, applications, get, default/java-webapp-student01, allow
p, student01, applications, sync, default/java-webapp-student01, allow
p, student01, applications, action/*, default/java-webapp-student01, allow
```

### **Student Role Permissions**
```
# Base student role
p, role:student, applications, get, */*, allow
p, role:student, applications, sync, */*, allow
p, role:student, applications, action/*, */*, allow
p, role:student, repositories, get, *, allow
p, role:student, clusters, get, *, allow
```

## 📋 **Updated Workflow**

### **Instructor Setup Process**
1. **Deploy students**: `./complete-student-setup-simple.sh 1 37`
2. **Configure ArgoCD RBAC**: `./configure-argocd-rbac.sh 1 37`
3. **Verify access**: Test student01 login to ArgoCD console

### **Student Day 3 Experience**
1. **Clone correct branch**: `git clone -b student01 https://github.com/kevin-biot/argocd`
2. **Run setup script**: `./setup-student-pipeline.sh`
3. **Git push happens**: Rendered manifests pushed to git automatically
4. **ArgoCD console access**: Login with student01/DevOps2025!
5. **See their application**: `java-webapp-student01` with sync permissions

## 🎯 **Key Takeaways**

- **ArgoCD operator controls RBAC** - Use Custom Resource, not ConfigMap
- **Git workflow critical** - Rendered manifests must be in git for ArgoCD
- **Application isolation works** - Students see only their apps
- **Sync permissions required** - action/* needed for full management

## 🚀 **Success Metrics**

When correctly configured:
- ✅ Students can login to ArgoCD console
- ✅ Students see only their applications  
- ✅ Students can sync/manage their applications
- ✅ Applications show "Synced" and "Healthy"
- ✅ GitOps workflow: git changes → automatic deployment
