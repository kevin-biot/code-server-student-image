# DevOps Bootcamp - Instructor Quick Start Guide

**Production-ready AWS OpenShift Container Service (OCS) deployment for DevOps training.**

## 🎯 Prerequisites

- ✅ AWS OpenShift cluster running
- ✅ `oc` CLI installed and logged in as cluster-admin
- ✅ OpenShift GitOps operator installed
- ✅ Shipwright operator installed
- ✅ Git repository access

## 🚀 One-Command Deployment

### Step 1: Build Code-Server Image
```bash
# Clone repository
git clone https://github.com/kevin-biot/code-server-student-image.git
cd code-server-student-image

# Build the code-server image with all DevOps tools
./build-and-verify.sh
```

### Step 2: Deploy Complete Student Environment
```bash
# Deploy 25 students with all RBAC and authentication
./complete-student-setup-simple.sh 1 25

# This creates:
# - 25 student namespaces with code-server pods
# - User accounts with proper permissions
# - OAuth authentication (htpasswd provider)
# - ArgoCD access for Day 3 GitOps exercises
```

## 📋 Student Access Information

**Announce to students:**

### OpenShift Console Access
- **URL**: `https://console-openshift-console.apps.YOUR-CLUSTER.com`
- **Username**: `student01`, `student02`, ... `student25`
- **Password**: `DevOps2025!`
- **Purpose**: Watch pipelines, ArgoCD applications, monitor deployments

### Code-Server Development Environment
- **URL Pattern**: `https://studentXX-code-server.apps.YOUR-CLUSTER.com`
- **Examples**:
  - student01: `https://student01-code-server.apps.YOUR-CLUSTER.com`
  - student02: `https://student02-code-server.apps.YOUR-CLUSTER.com`
- **Login**: Individual auto-generated passwords (displayed in browser)
- **Purpose**: Development, CLI access, exercise execution

## 🛠️ Tools Pre-installed in Code-Server

Each student environment includes:
- **Kubernetes/OpenShift**: `oc`, `kubectl`
- **CI/CD**: `tkn` (Tekton), `helm`
- **GitOps**: `argocd`
- **Infrastructure as Code**: `pulumi`
- **Development**: Node.js 20, Python 3.11, Java 17, Maven, Gradle
- **Utilities**: `yq`, `jq`, `git`, `curl`, `vim`, etc.

## 🔍 Validation Commands

```bash
# Check all students are running
oc get pods --all-namespaces | grep code-server | grep Running

# Test student authentication
oc login -u student01 -p 'DevOps2025!'
oc get pods -n student01

# Verify student cannot access other namespaces
oc get pods -n student02  # Should be forbidden

# Check ArgoCD access for Day 3
oc get pods -n openshift-gitops
```

## 🧹 Cleanup Commands

```bash
# Remove all student environments
./teardown-students.sh all all confirm

# Remove user accounts (if needed)
for i in {01..25}; do
  oc delete user student${i} || true
  oc delete identity htpasswd_provider:student${i} || true
done
```

## 🎓 Course Structure

### Day 1: Infrastructure as Code (Pulumi)
- Students use **Code-Server** for development
- Students use **Console** to watch resource creation

### Day 2: CI/CD Pipelines (Tekton)  
- Students create pipelines in **Code-Server**
- Students monitor pipeline execution in **Console**

### Day 3: GitOps (ArgoCD)
- Students manage applications via **ArgoCD CLI** in Code-Server
- Students watch application sync in **ArgoCD Console**

## 🔐 Security Model

- ✅ **Namespace Isolation**: Students have admin access only to their namespace
- ✅ **Shared Resource Access**: View-only access to `devops` and `openshift-gitops`
- ✅ **Console Visibility**: Students can see cluster structure for learning
- ✅ **No Cluster Admin**: Students cannot modify cluster-level resources
- ✅ **Multi-tenant Safe**: Students cannot interfere with each other

## 📚 Additional Resources

- **Student Guide**: `STUDENT-QUICK-START.md`
- **Troubleshooting**: Check pod logs, events, RBAC with `oc describe`
- **Legacy Scripts**: Available in `legacy/` directory if needed

## 🆘 Common Issues

### Students Can't Login to Console
```bash
# Check OAuth pods
oc get pods -n openshift-authentication
# Restart OAuth if needed
oc delete pods -n openshift-authentication -l app=oauth-openshift
```

### Code-Server Not Responding
```bash
# Check student pod status
oc get pods -n studentXX
oc describe pod -n studentXX
oc logs -n studentXX -l app=code-server
```

### Build Failures
```bash
# Check Shipwright build status
oc get buildrun -n devops
oc logs buildrun/BUILDRUN-NAME -n devops
```

---

**🎯 Total Setup Time: ~15-20 minutes for 25 students**
**🎓 Ready for production DevOps bootcamp delivery!**
