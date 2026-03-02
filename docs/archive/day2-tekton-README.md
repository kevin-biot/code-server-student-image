# Java Webapp DevOps Workshop

## Overview

This repository contains a complete DevOps workshop project featuring a simple Java servlet application with automated CI/CD pipelines. The project demonstrates modern container build and deployment practices using OpenShift Pipelines (Tekton), Shipwright Build, and Kubernetes manifests. It is designed for hands-on learning in DevOps workshops and educational environments.

## Project Structure

```
├── setup-student-pipeline.sh          # Automated student setup script
├── src/                               # Java application source code
│   └── main/
│       ├── java/com/example/         # Servlet implementation
│       └── webapp/                   # Web application files
├── k8s/                              # Kubernetes deployment manifests
│   ├── rbac/                         # Role-based access control
│   ├── deployment.yaml               # Application deployment
│   ├── service.yaml                  # Service definition
│   └── route.yaml                    # OpenShift route (external access)
├── tekton/                           # CI/CD pipeline definitions
│   ├── clustertasks/                 # Shared pipeline tasks
│   ├── tasks/                        # Custom pipeline tasks
│   ├── pipeline.yaml                 # Main CI/CD pipeline
│   ├── pvc.yaml                      # Persistent volume claim
│   └── pipeline-run.yaml             # Pipeline execution template
├── shipwright/                       # Container build configuration
│   └── build/                        # Build definitions and strategies
├── Dockerfile                        # Container image definition
└── pom.xml                          # Maven build configuration
```

## Application Details

**Technology Stack:**
- **Language:** Java 17
- **Framework:** Java Servlets (javax.servlet-api 4.0.1)
- **Build Tool:** Maven
- **Container Runtime:** OpenShift/Kubernetes
- **Web Server:** Embedded servlet container

**Application Features:**
- Simple "Hello World" servlet responding at `/hello`
- Basic index page demonstrating web front end
- Health check endpoints for readiness and liveness probes
- Containerized deployment with proper resource limits

## Quick Start for Students

### Prerequisites

- Access to an OpenShift cluster with:
  - OpenShift Pipelines (Tekton) operator installed
  - Shipwright Build operator installed
  - Appropriate RBAC permissions for your namespace
- Access to a code-server environment or terminal with `oc` and `tkn` CLI tools

### Workshop Kickoff Steps

Follow these exact steps in your code-server terminal for the workshop:

```bash
# 1. Navigate to your workshop directory
cd ~/workspace/labs/day2-tekton

# 2. Clone the workshop repository (development branch)
git clone -b dev https://github.com/kevin-biot/devops-workshop.git

# 3. Enter the project directory
cd devops-workshop

# 4. Make the setup script executable
chmod +x ./setup-student-pipeline.sh

# 5. Run the automated setup script
./setup-student-pipeline.sh
```

### What the Setup Script Does

When you run `./setup-student-pipeline.sh`, it will:

1. **🧑‍🎓 Prompt for your student namespace** (e.g., `student01`)
2. **🌐 Ask for Git repository URL** (defaults to `https://github.com/kevin-biot/devops-workshop.git`)
3. **📁 Confirm your configuration** before proceeding

The script then automatically:

4. **✅ Renders YAML templates** with your specific namespace:
   - `pipeline-app-role.yaml` - RBAC permissions
   - `pipeline-app-binding.yaml` - Role binding
   - `java-webapp-imagestream.yaml` - Container registry
   - `service.yaml` - Application service
   - `route.yaml` - External access route
   - `pipeline.yaml` - CI/CD pipeline definition
   - `build.yaml` - Shipwright build configuration
   - Plus templates for manual execution

5. **🚀 Applies infrastructure resources** to your namespace:
   - Creates RBAC roles and bindings
   - Sets up ImageStream for container registry
   - Creates Service and Route for application access
   - Installs Tekton pipeline and custom tasks
   - Configures Shipwright build

6. **📂 Creates a `rendered_<your-namespace>` directory** with all your personalized YAML files

### Manual Execution Steps

After the setup script completes successfully, you'll see detailed instructions. Follow these steps exactly:

```bash
# 1. Navigate to your rendered configuration directory
cd rendered_<your-namespace>
# Example: cd rendered_student01

# 2. Trigger a Shipwright build (builds your container image)
oc delete buildrun --all -n <your-namespace> --ignore-not-found
oc create -f buildrun.yaml -n <your-namespace>

# 3. Execute the complete CI/CD pipeline
oc delete pipelinerun --all -n <your-namespace> --ignore-not-found
oc apply -f pipeline-run.yaml -n <your-namespace>
```

**Important Notes:**
- Replace `<your-namespace>` with your actual namespace (e.g., `student01`)
- The delete commands are safe to run - they clean up any previous attempts
- Both commands are "re-run safe" - you can execute them multiple times

### Expected Output from Setup Script

When the setup script runs successfully, you'll see output similar to this:

```
🔧 Student Pipeline Setup Script
🧑‍🎓  Enter student namespace: student01
🌐  Enter Git repo URL [default: https://github.com/kevin-biot/devops-workshop.git]: 

📁 Rendering YAMLs for:
   🏷️  Namespace: student01
   📦 Git Repo:  https://github.com/kevin-biot/devops-workshop.git
❓ Proceed with these values? (y/n): y

🛠️  Rendering files into: rendered_student01
✅ Rendered: rendered_student01/pipeline-app-role.yaml
✅ Rendered: rendered_student01/java-webapp-imagestream.yaml
✅ Rendered: rendered_student01/service.yaml
✅ Rendered: rendered_student01/route.yaml
✅ Rendered: rendered_student01/pipeline.yaml
✅ Rendered: rendered_student01/build.yaml
[... more files ...]

🚀 Applying initial resources to namespace: student01
➡️  Applying pipeline-app-role.yaml
➡️  Applying java-webapp-imagestream.yaml
[... applying resources ...]

🎯 Applying Tekton tasks (no templating needed):
➡️  Applying deploy.yaml
➡️  Applying shipwright-trigger.yaml

📌 Next steps for the student
  1.  cd rendered_student01
  2.  Trigger a Shipwright build (re-run safe)
  3.  Kick off the full pipeline (re-run safe)
```

## Monitoring and Validation

**Check build status:**
```bash
# Monitor BuildRun progress
oc get buildrun -n <your-namespace>
oc get pods -n <your-namespace> | grep buildrun
oc logs -f <buildrun-pod-name> -n <your-namespace>
```

**Monitor pipeline execution:**
```bash
# Using Tekton CLI (recommended)
tkn pipelinerun list -n <your-namespace>
tkn pipelinerun logs java-webapp-run -f -n <your-namespace>

# Using oc CLI
oc get pipelinerun -n <your-namespace>
oc logs -f pipelinerun/java-webapp-run -n <your-namespace>
```

**Access your deployed application:**
```bash
# Get the external URL
oc get route java-webapp -n <your-namespace>

# Test the application
export APP_URL="https://$(oc get route java-webapp -n <your-namespace> -o jsonpath='{.spec.host}')"
echo "App URL: $APP_URL"
curl -k $APP_URL

# Check application pods
oc get pods -n <your-namespace> -l app=java-webapp
oc get svc java-webapp -n <your-namespace>
```

## Reset Instructions

If you encounter issues or want to start fresh, follow these reset steps:

### Complete Environment Reset

```bash
# 1. Clean up all deployed resources in your namespace
oc delete deployment java-webapp -n <your-namespace>
oc delete service java-webapp -n <your-namespace>
oc delete route java-webapp -n <your-namespace>
oc delete imagestream java-webapp -n <your-namespace>

# 2. Clean up build and pipeline resources
oc delete buildrun --all -n <your-namespace>
oc delete pipelinerun --all -n <your-namespace>
oc delete pipeline java-webapp-pipeline -n <your-namespace>
oc delete task deploy shipwright-trigger -n <your-namespace>

# 3. Verify cleanup completed
oc get all -l app=java-webapp -n <your-namespace>
# Should show: No resources found in <your-namespace> namespace.
```

### Restart from Beginning

After cleaning up resources, you'll need to start over:

```bash
# 1. Navigate back to your workspace
cd ~/workspace/labs/day2-tekton

# 2. Remove the existing repository
rm -rf devops-workshop

# 3. Start fresh with the workshop steps
git clone -b dev https://github.com/kevin-biot/devops-workshop.git
cd devops-workshop
chmod +x ./setup-student-pipeline.sh
./setup-student-pipeline.sh
```

**Note:** After running the reset commands, you must restart from the git clone step as all your rendered configurations will be lost.

## Common Issues and Quick Fixes

### Setup Script Permission Error

If you see `Permission denied` when running the setup script:

```bash
# This will happen if you see:
# bash: ./setup-student-pipeline.sh: Permission denied

# Fix it with:
chmod +x ./setup-student-pipeline.sh

# Then run the script:
./setup-student-pipeline.sh
```

### File Not Found During Manual Steps

If you see `error: the path "buildrun.yaml" does not exist`:

```bash
# Make sure you're in the correct directory:
cd rendered_<your-namespace>
# Example: cd rendered_student01

# Then run the commands:
oc create -f buildrun.yaml -n <your-namespace>
```

## Troubleshooting Guide

### Common Issues During Workshop

**Build Failures:**
```bash
# Check Maven build logs
oc logs -f buildrun/<buildrun-name> -n <your-namespace>

# Verify Java/Maven configuration
oc describe buildrun/<buildrun-name> -n <your-namespace>
```

**Pipeline Failures:**
```bash
# Check individual task logs
tkn pipelinerun describe java-webapp-run -n <your-namespace>
tkn taskrun logs <task-run-name> -n <your-namespace>

# Verify workspace and PVC
oc get pvc -n <your-namespace>
oc describe pvc pipeline-workspace -n <your-namespace>
```

**Deployment Issues:**
```bash
# Check pod status and logs
oc get pods -n <your-namespace> -l app=java-webapp
oc logs deployment/java-webapp -n <your-namespace>
oc describe deployment java-webapp -n <your-namespace>

# Verify service and route configuration
oc get svc,route -n <your-namespace>
```

**Resource Constraints:**
```bash
# Check resource quotas and limits
oc describe resourcequota -n <your-namespace>
oc describe limitrange -n <your-namespace>
oc get events -n <your-namespace> --sort-by=.metadata.creationTimestamp
```

## CI/CD Pipeline Architecture

### Pipeline Stages

The Tekton pipeline implements a complete CI/CD workflow:

1. **Git Clone** - Fetches source code from the repository
2. **Maven Build** - Compiles Java code and packages as WAR file
3. **Sanity Check** - Validates the generated WAR file
4. **Container Build** - Uses Shipwright to build container image
5. **Deploy** - Deploys the application to Kubernetes

### Build Strategy

**Shipwright Build Configuration:**
- Uses Buildah strategy for container builds
- Integrates with OpenShift internal image registry
- Automatic image tagging and storage
- Build trigger via Tekton pipeline

**Maven Configuration:**
- Java 17 compilation target
- WAR packaging for servlet deployment
- Embedded dependency management
- Optimized for containerized environments

## Workshop Learning Objectives

This project demonstrates key DevOps concepts:

**Container Technologies:**
- Dockerfile best practices
- Multi-stage builds and optimization
- Container registry integration

**CI/CD Pipelines:**
- Pipeline as Code with Tekton
- Automated testing and validation
- Build triggers and webhooks

**Kubernetes Deployment:**
- Declarative configuration management
- Service discovery and networking
- Health checks and monitoring

**Security and RBAC:**
- Namespace isolation
- Service account permissions
- Image security scanning

## Advanced Exercises

**Pipeline Enhancements:**
- Add unit testing stage
- Implement security scanning
- Add deployment strategies (blue-green, canary)

**Monitoring Integration:**
- Add Prometheus metrics
- Implement custom health checks
- Configure alerting rules

**GitOps Workflow:**
- Integrate with ArgoCD
- Implement configuration management
- Add environment promotion pipeline

## Support and Resources

**Documentation:**
- [OpenShift Pipelines Documentation](https://docs.openshift.com/container-platform/latest/cicd/pipelines/understanding-openshift-pipelines.html)
- [Shipwright Build Documentation](https://shipwright.io/docs/)
- [Tekton Pipeline Documentation](https://tekton.dev/docs/)

**Helpful Commands:**
```bash
# Monitor cluster resources
oc adm top nodes
oc adm top pods -n <your-namespace>

# Access Tekton Dashboard
open https://tekton-dashboard.<cluster-domain>

# Emergency cleanup
oc delete all -l app=java-webapp -n <your-namespace>
```

**Workshop Support:**
- For technical issues, check the troubleshooting section above
- For workshop-specific questions, contact your instructor
- For infrastructure issues, verify cluster status and resources

---

## File Templates

The setup script uses the following template variables:
- `{{NAMESPACE}}` - Replaced with your student namespace
- `{{GIT_REPO_URL}}` - Replaced with the workshop repository URL

All rendered files are placed in the `rendered_<namespace>` directory for easy reference and manual execution.
