# Day 3 GitOps Lab - OpenShift Pipelines & ArgoCD

## 🎯 Lab Overview
In this lab, you'll build a complete GitOps pipeline that:
- Builds a container image using OpenShift Pipelines
- Deploys applications automatically using ArgoCD
- Demonstrates continuous deployment workflows

## 📋 Prerequisites
- GitHub Personal Access Token (PAT) with repo permissions
- Access to OpenShift cluster
- Basic understanding of Kubernetes/OpenShift concepts

## 🚀 Step-by-Step Instructions

### Step 1: Clone the ArgoCD Repository
First, clone the lab repository and navigate to the lab directory:

```bash
# Navigate to the lab directory
cd /home/coder/workspace/labs/day3-gitops

# Clone the argocd repository
git clone https://github.com/kevbrow/argocd.git .

# Verify you're in the correct directory with lab files
ls -la
# You should see: setup-git-credentials.sh, setup-student-pipeline.sh, buildrun-beta.yaml, pipeline-run.yaml, etc.
```

### Step 2: Setup Git Credentials
Configure your Git credentials for the pipeline:

```bash
# Run the git credentials setup script (from the repo directory)
./setup-git-credentials.sh
```

This script will prompt you for:
- GitHub username
- GitHub Personal Access Token (PAT)
- Email address

### Step 3: Setup Student Pipeline
Configure your personalized pipeline environment:

```bash
# Run the student pipeline setup (from the repo directory)
./setup-student-pipeline.sh
```

This script will:
- Create necessary OpenShift resources
- Configure pipeline permissions
- Set up your student namespace

### Step 4: Create and Run the Build
Execute the build process:

```bash
# Create the BuildRun resource (from the repo directory)
oc create -f buildrun-beta.yaml -n student01

# Apply the pipeline run (from the repo directory)
oc apply -f pipeline-run.yaml -n student01
```

### Step 5: Monitor Pipeline Execution
Watch your pipeline progress:

```bash
# Check pipeline run status
oc get pipelineruns -n student01

# Follow pipeline logs
oc logs -f pipelinerun/<pipeline-run-name> -n student01

# Check build status
oc get buildruns -n student01
```

### Step 6: Access ArgoCD UI
Once the pipeline completes:

1. Get ArgoCD URL:
   ```bash
   oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}'
   ```
   **Example URL:** `https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net`

2. Get admin password:
   ```bash
   oc get secret argocd-initial-admin-secret -n openshift-gitops -o jsonpath='{.data.password}' | base64 -d
   ```

3. Login to ArgoCD UI with:
   - Username: `admin`
   - Password: (from step 2)

4. Navigate to your student application:
   **Example Application URL:** `https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net/applications/openshift-gitops/java-webapp-student01?view=tree&resource=`

### Step 7: Verify Deployment
Check that your application is deployed:

```bash
# Check application pods
oc get pods -n student01

# Check application service
oc get svc -n student01

# Get application route
oc get route -n student01
```

## 🎯 Success Criteria
Your lab is successful when:
- [ ] ArgoCD repository cloned successfully
- [ ] Git credentials configured
- [ ] Student pipeline setup completed
- [ ] Pipeline runs without errors
- [ ] Container image is built and pushed
- [ ] Application appears in ArgoCD UI
- [ ] Application pods are running
- [ ] Application is accessible via route

## 🔧 Troubleshooting

### Pipeline Fails
```bash
# Check pipeline logs
oc describe pipelinerun <pipeline-run-name> -n student01

# Check task logs
oc logs -f <task-pod-name> -n student01
```

### Build Fails
```bash
# Check buildrun status
oc describe buildrun <buildrun-name> -n student01

# Check build logs
oc logs -f buildrun/<buildrun-name> -n student01
```

### ArgoCD Issues
```bash
# Check ArgoCD application status
oc get applications -n openshift-gitops

# Check ArgoCD logs
oc logs -f deployment/argocd-application-controller -n openshift-gitops
```

### Common Issues
1. **Repository not cloned**: Ensure you're in `/home/coder/workspace/labs/day3-gitops` and have cloned the argocd repo
2. **Git credentials not configured**: Re-run `./setup-git-credentials.sh`
3. **Scripts not executable**: Run `chmod +x *.sh` in the repo directory
4. **Namespace permissions**: Ensure you're in the correct namespace
5. **Image push failures**: Check registry credentials and permissions
6. **ArgoCD sync issues**: Check Git repository accessibility

## 📚 Additional Resources
- [OpenShift Pipelines Documentation](https://docs.openshift.com/container-platform/latest/cicd/pipelines/understanding-openshift-pipelines.html)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Tekton Documentation](https://tekton.dev/docs/)

## 🎉 Next Steps
After completing this lab:
1. Explore ArgoCD application management
2. Try modifying the application code
3. Observe automatic redeployment
4. Experiment with different deployment strategies

---
**Need Help?** Ask your instructor or check the troubleshooting section above.