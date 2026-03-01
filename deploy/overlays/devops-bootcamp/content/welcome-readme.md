# DevOps Workshop Environment

Welcome to your complete cloud-native development environment! This workspace contains everything you need for the 3-day DevOps workshop.

## **FIRST TIME HERE? START WITH THIS!**

**[READ THE STUDENT QUICK START GUIDE](./STUDENT-QUICK-START.md)**

If you've never used a code-server/VS Code environment before, please **click on `STUDENT-QUICK-START.md`** in the file explorer on the left. This guide will teach you:
- How to use this web-based development environment
- How to open and use the terminal
- Essential keyboard shortcuts
- Your first DevOps commands
- Troubleshooting common issues

> This is a laptop-free workshop! Everything runs in your browser - no downloads or installs needed.

## Workshop Structure

### Day 1: Infrastructure as Code with Pulumi (Focus: IaC Concepts)
- **Location**: `labs/day1-pulumi/`
- **Focus**: Learning Infrastructure as Code with Pulumi
- **Tools**: Pulumi, Kubernetes, OpenShift Routes, PostgreSQL
- **Approach**: Uses instructor pre-built images for reliable, fast deployment

### Day 2: Advanced CI/CD Pipelines
- **Location**: `labs/day2-tekton/`
- **Focus**: Enterprise-grade CI/CD pipelines
- **Tools**: Tekton Pipelines, Triggers, GitOps integration

### Day 3: GitOps with ArgoCD
- **Location**: `labs/day3-gitops/`
- **Focus**: Implement GitOps workflows and automation
- **Tools**: ArgoCD, Git workflows, Application sync

## Pre-installed Tools

### **Languages & Runtimes**
- Java 17 with Maven and Gradle
- Python 3 with pip and virtual environments
- Node.js 20 with npm and TypeScript support
- Build tools for all major languages

### **DevOps & Cloud Native**
- OpenShift CLI (`oc`) - Platform management
- Tekton CLI (`tkn`) - Pipeline operations
- Kubernetes CLI (`kubectl`) - Container orchestration
- Pulumi CLI - Infrastructure as Code (passphrase pre-configured)
- Helm - Package management
- ArgoCD CLI - GitOps workflows

### **Development Tools**
- VS Code (this interface) with DevOps extensions
- Git with completion and templates
- Testing frameworks (pytest, JUnit, Jest)
- JSON/YAML processors (jq, yq)
- HTTP tools (curl, wget)

## Directory Structure

```
workspace/
├── projects/          # Your main development work
├── labs/
│   ├── day1-pulumi/   # Day 1: Infrastructure as Code with Pulumi
│   ├── day2-tekton/   # Day 2: Advanced CI/CD Pipelines
│   └── day3-gitops/   # Day 3: GitOps with ArgoCD
├── examples/          # Sample code and references
└── templates/         # Workshop exercise templates
```

## Quick Start Commands

### **OpenShift Authentication**
```bash
# Login to your OpenShift cluster (if needed)
oc whoami

# Verify your access and namespace
oc project $STUDENT_NAMESPACE
```

### **Day 1: Pulumi Infrastructure as Code**
```bash
cd labs/day1-pulumi

# Clone the IaC workshop repository
git clone <instructor-provided-repo-url>

# Navigate to the IaC project
cd IaC

# Setup Pulumi environment (no passphrase needed!)
npm install
pulumi login --local
pulumi stack init dev
pulumi config set studentNamespace $STUDENT_NAMESPACE
pulumi config set --secret dbPassword MySecurePassword123

# Preview what will be deployed
pulumi preview

# Deploy infrastructure (fast - uses pre-built images!)
pulumi up
```

### **Day 2: Advanced Tekton Pipelines**
```bash
cd labs/day2-tekton
oc apply -f tekton/clustertasks/
oc apply -f tekton/pipeline.yaml
tkn pipeline start advanced-pipeline
```

### **Day 3: ArgoCD GitOps**
```bash
cd labs/day3-gitops
argocd login <argocd-server>
argocd app create my-app --repo <git-repo> --path manifests
```

### **Development Workflow (Simplified for Learning)**
```bash
# Day 1: Focus on Infrastructure as Code
cd labs/day1-pulumi
git clone <instructor-provided-repo-url>
cd IaC
pulumi preview  # See what will be created
pulumi up       # Deploy infrastructure
oc get all      # View deployed resources
oc get routes   # Get application URL

# Scale your application
# Edit index.ts to change replicas, then:
pulumi preview  # Preview changes
pulumi up       # Apply changes

# Clean up resources
pulumi destroy
```

## Important Links

When your applications are deployed, you can access:

- **Your Web Application**: Check `pulumi stack output appUrl` or `oc get routes`
- **OpenShift Console**: `https://console-openshift-console.<cluster-domain>`
- **Tekton Dashboard**: `https://tekton-dashboard.<cluster-domain>`
- **ArgoCD UI**: `https://argocd.<cluster-domain>`

## Pro Tips

1. **Terminal Access**: Use `Terminal > New Terminal` for command line
2. **File Explorer**: Use the left sidebar to navigate files
3. **Git Integration**: Built-in Git support with visual diff
4. **Extensions**: Pre-installed extensions for YAML, Java, TypeScript
5. **Auto-completion**: Tab completion enabled for all CLI tools
6. **No Passphrases**: Pulumi passphrase pre-configured via environment variable
7. **Fast Deployment**: Day 1 uses pre-built images for reliable workshop experience

## Day 1 Learning Objectives

**Infrastructure as Code with Pulumi:**
- Understand declarative infrastructure management
- Learn resource dependencies and ordering
- Practice configuration management with secrets
- Experience infrastructure scaling and updates
- Explore Kubernetes networking and services
- Use OpenShift Routes for external access

**Key Concepts Demonstrated:**
- Pulumi stack management
- Resource providers and configurations
- Database deployment and persistence
- Application deployment patterns
- Service networking and discovery
- External access configuration

## Need Help?

- **Documentation**: Check `examples/` directory for samples
- **Logs**: Use `oc logs`, `pulumi logs`, or check OpenShift console
- **Debugging**: All tools support `--help` flag
- **Instructor**: Raise your hand or ask in chat

---

**Ready to start your Infrastructure as Code journey? Begin with Day 1 in the `labs/day1-pulumi` directory!**
