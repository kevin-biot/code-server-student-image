#!/bin/bash
# Enhanced startup.sh - Complete DevOps workshop environment setup

# Detect student namespace from environment or derive from hostname
if [ -z "$STUDENT_NAMESPACE" ]; then
    STUDENT_NAMESPACE=$(echo $HOSTNAME | sed 's/code-server.*//' | sed 's/.*-//')
    if [ -z "$STUDENT_NAMESPACE" ]; then
        STUDENT_NAMESPACE="student01"
    fi
fi
export STUDENT_NAMESPACE

# Set up Git configuration if not already done
if [[ ! -f /home/coder/.gitconfig && -f /home/coder/.gitconfig-template ]]; then
    cp /home/coder/.gitconfig-template /home/coder/.gitconfig
    sed -i "s/STUDENT_ID/$STUDENT_NAMESPACE/g" /home/coder/.gitconfig
fi

# Create comprehensive welcome message with quick start guide reference
cat > /home/coder/workspace/README.md << 'EOF'
# 🚀 DevOps Workshop Environment

Welcome to your complete cloud-native development environment! This workspace contains everything you need for the 3-day DevOps workshop.

## 👋 **FIRST TIME HERE? START WITH THIS!**

📖 **[READ THE STUDENT QUICK START GUIDE](./STUDENT-QUICK-START.md)** 📖

If you've never used a code-server/VS Code environment before, please **click on `STUDENT-QUICK-START.md`** in the file explorer on the left. This guide will teach you:
- How to use this web-based development environment
- How to open and use the terminal
- Essential keyboard shortcuts
- Your first DevOps commands
- Troubleshooting common issues

> 🎯 **This is a laptop-free workshop!** Everything runs in your browser - no downloads or installs needed.

## 📚 Workshop Structure

### 🏗️ Day 1: Infrastructure as Code with Pulumi
- **Location**: `labs/day1-pulumi/`
- **Focus**: Provision infrastructure using TypeScript
- **Tools**: Pulumi, Redis, Load Testing, Web Applications

### 🔄 Day 2: CI/CD Pipelines with Tekton
- **Location**: `labs/day2-tekton/`  
- **Focus**: Build enterprise-grade CI/CD pipelines
- **Tools**: Tekton, Shipwright, GitOps, Container Registry

### 🔄 Day 3: GitOps with ArgoCD
- **Location**: `labs/day3-gitops/`
- **Focus**: Implement GitOps workflows and automation
- **Tools**: ArgoCD, Git workflows, Application sync

## 🛠️ Pre-installed Tools

### **Languages & Runtimes**
- ☕ **Java 17** with Maven and Gradle
- 🐍 **Python 3** with pip and virtual environments
- 🟢 **Node.js** with npm and TypeScript support
- 🔧 **Build tools** for all major languages

### **DevOps & Cloud Native**
- 🔴 **OpenShift CLI** (`oc`) - Platform management
- ⚙️ **Tekton CLI** (`tkn`) - Pipeline operations
- ☸️ **Kubernetes CLI** (`kubectl`) - Container orchestration
- 🏗️ **Pulumi CLI** - Infrastructure as Code
- 📦 **Helm** - Package management
- 🐳 **Docker** - Container operations
- 🔄 **ArgoCD CLI** - GitOps workflows

### **Development Tools**
- 📝 **VS Code** (this interface) with DevOps extensions
- 🔀 **Git** with completion and templates
- 🧪 **Testing frameworks** (pytest, JUnit, Jest)
- 📊 **JSON/YAML processors** (jq, yq)
- 🌐 **HTTP tools** (curl, wget)

## 📁 Directory Structure

```
workspace/
├── projects/          # Your main development work
├── labs/
│   ├── day1-pulumi/   # Day 1: Infrastructure as Code
│   ├── day2-tekton/   # Day 2: CI/CD Pipelines
│   └── day3-gitops/   # Day 3: GitOps with ArgoCD
├── examples/          # Sample code and references
└── templates/         # Workshop exercise templates
```

## 🚀 Quick Start Commands

### **OpenShift Authentication**
```bash
# Login to your OpenShift cluster
oc login <cluster-url>

# Verify your access and namespace
oc whoami
oc project $STUDENT_NAMESPACE
```

### **Day 1: Pulumi Infrastructure**
```bash
cd labs/day1-pulumi
npm install
pulumi stack init dev
pulumi up
```

### **Day 2: Tekton Pipelines**
```bash
cd labs/day2-tekton
oc apply -f tekton/
tkn pipeline start java-webapp-pipeline
```

### **Day 3: ArgoCD GitOps**
```bash
cd labs/day3-gitops
argocd login <argocd-server>
argocd app create my-app --repo <git-repo> --path manifests --dest-server <k8s-server>
```

### **Development Workflow**
```bash
# Create new project
mkdir projects/my-app && cd projects/my-app
git init

# Java development
mvn archetype:generate
mvn clean package

# Container operations
docker build -t my-app .
oc new-app --docker-image=my-app

# Pipeline management
tkn pipeline list
tkn pipelinerun logs --last -f

# GitOps management
argocd app list
argocd app sync my-app
```

## 🔗 Important Links

When your applications are deployed, you can access:

- 🌐 **Your Web Application**: `https://$STUDENT_NAMESPACE-webapp.apps.cluster.domain`
- 📊 **Redis Commander**: `https://$STUDENT_NAMESPACE-redis.apps.cluster.domain`
- 🎯 **Load Generator**: `https://$STUDENT_NAMESPACE-loadgen.apps.cluster.domain`
- 🖥️ **OpenShift Console**: `https://console-openshift-console.apps.cluster.domain`
- 📈 **Tekton Dashboard**: `https://tekton-dashboard.apps.cluster.domain`
- 🔄 **ArgoCD UI**: `https://argocd.apps.cluster.domain`

## 💡 Pro Tips

1. **Terminal Access**: Use `Terminal → New Terminal` for command line
2. **File Explorer**: Use the left sidebar to navigate files
3. **Git Integration**: Built-in Git support with visual diff
4. **Extensions**: Pre-installed extensions for YAML, Java, TypeScript
5. **Auto-completion**: Tab completion enabled for all CLI tools
6. **Shortcuts**: `Ctrl+Shift+P` for command palette

## 🆘 Need Help?

- **Documentation**: Check `examples/` directory for samples
- **Logs**: Use `oc logs`, `tkn logs`, or check OpenShift console
- **Debugging**: All tools support `--help` flag
- **Instructor**: Raise your hand or ask in chat

---

**🎯 Ready to start your DevOps journey? Begin with Day 1 in the `labs/day1-pulumi` directory!**
EOF

# Set up Day 1 Pulumi exercise structure
mkdir -p /home/coder/workspace/labs/day1-pulumi
cd /home/coder/workspace/labs/day1-pulumi

if [ ! -f package.json ]; then
    # Create Pulumi project structure
    cat > package.json << 'EOF'
{
  "name": "student-infrastructure",
  "version": "1.0.0",
  "description": "Day 1: Infrastructure as Code with Pulumi",
  "main": "index.ts",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "@pulumi/kubernetes": "^4.0.0",
    "@pulumi/pulumi": "^3.0.0"
  },
  "devDependencies": {
    "@types/node": "^18.0.0",
    "typescript": "^4.9.0"
  }
}
EOF

    cat > Pulumi.yaml << 'EOF'
name: student-infrastructure
runtime: nodejs
description: Day 1 - Provision complete microservices infrastructure
config:
  student-infrastructure:namespace:
    description: Student namespace for resources
    default: student01
EOF

    cat > README.md << 'EOF'
# Day 1: Infrastructure as Code with Pulumi

## Objective
Use Pulumi to provision a complete microservices architecture including web application, database, background worker, and load testing tools.

## Getting Started

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Initialize Pulumi stack**:
   ```bash
   pulumi stack init dev
   pulumi config set student-infrastructure:namespace $STUDENT_NAMESPACE
   ```

3. **Complete the TODOs in index.ts**

4. **Deploy infrastructure**:
   ```bash
   pulumi up
   ```

## Components to Build
- Redis database and message broker
- Web application with Redis integration  
- Background job worker
- Load generator with web interface
- Redis Commander for data visualization

## Success Criteria
✅ All 5 pods running in OpenShift console
✅ Web application accessible via browser
✅ Redis Commander showing live data
✅ Load generator creating traffic
✅ Background worker processing jobs
EOF
fi

# Set up Day 2 Tekton exercise structure
mkdir -p /home/coder/workspace/labs/day2-tekton
cd /home/coder/workspace/labs/day2-tekton

if [ ! -f README.md ]; then
    cat > README.md << 'EOF'
# Day 2: CI/CD Pipelines with Tekton

## Objective
Build an enterprise-grade CI/CD pipeline using Tekton and Shipwright for automated application delivery.

## Pipeline Architecture
1. **Git Clone** - Checkout source code
2. **Maven Build** - Compile and test Java application
3. **Shipwright Build** - Create container image
4. **Deploy** - Rolling update to OpenShift
5. **Test** - Automated validation

## Getting Started

1. **Deploy pipeline infrastructure**:
   ```bash
   oc apply -f tekton/clustertasks/
   oc apply -f tekton/pipeline.yaml
   oc apply -f shipwright/build/
   ```

2. **Trigger pipeline execution**:
   ```bash
   oc create -f tekton/pipeline-run.yaml
   ```

3. **Monitor pipeline progress**:
   ```bash
   tkn pipelinerun logs --last -f
   ```

## Advanced Features
- Parallel task execution
- Conditional pipeline logic
- GitOps integration with ArgoCD
- Security scanning in builds
- Multi-environment deployments

## Success Criteria
✅ Pipeline executes all stages successfully
✅ Container image built and pushed to registry
✅ Application deployed with zero downtime
✅ Automated tests pass
✅ GitOps sync successful
EOF
fi

# Set up Day 3 GitOps exercise structure
mkdir -p /home/coder/workspace/labs/day3-gitops
cd /home/coder/workspace/labs/day3-gitops

if [ ! -f README.md ]; then
    cat > README.md << 'EOF'
# Day 3: GitOps with ArgoCD

## Objective
Implement GitOps workflows using ArgoCD for automated application deployment and management.

## GitOps Principles
1. **Declarative** - Describe desired state in Git
2. **Versioned** - All changes tracked in version control
3. **Pulled** - Deployment agents pull changes automatically
4. **Continuously Reconciled** - Automatic drift detection and correction

## Getting Started

1. **Access ArgoCD UI**:
   ```bash
   # Get ArgoCD admin password
   argocd admin initial-password -n argocd
   
   # Login via CLI
   argocd login <argocd-server>
   ```

2. **Create Application**:
   ```bash
   argocd app create my-webapp \
     --repo <your-git-repo> \
     --path k8s \
     --dest-server https://kubernetes.default.svc \
     --dest-namespace $STUDENT_NAMESPACE
   ```

3. **Sync Application**:
   ```bash
   argocd app sync my-webapp
   ```

## Workshop Activities
- Create ArgoCD applications
- Configure Git repositories for GitOps
- Implement application health checks
- Set up automated sync policies
- Monitor deployment status and health

## Success Criteria
✅ ArgoCD application created and synced
✅ Git-based configuration changes trigger deployments
✅ Application health monitoring working
✅ Rollback functionality tested
✅ Multi-environment promotion workflow
EOF
fi

# Copy student quick start guide to workspace
if [ -f /home/coder/STUDENT-QUICK-START.md ]; then
    cp /home/coder/STUDENT-QUICK-START.md /home/coder/workspace/STUDENT-QUICK-START.md
fi

# Set up examples directory with useful references
mkdir -p /home/coder/workspace/examples/{kubernetes,tekton,pulumi,docker,argocd}

# Auto-login to OpenShift if credentials are available
if [ -n "$OPENSHIFT_TOKEN" ] && [ -n "$OPENSHIFT_SERVER" ]; then
    oc login --token="$OPENSHIFT_TOKEN" --server="$OPENSHIFT_SERVER" --insecure-skip-tls-verify=true
    oc project "$STUDENT_NAMESPACE" 2>/dev/null || echo "Note: Project $STUDENT_NAMESPACE not found"
fi

# Set up shell environment
echo "export STUDENT_NAMESPACE=$STUDENT_NAMESPACE" >> /home/coder/.bashrc
echo "export PULUMI_SKIP_UPDATE_CHECK=true" >> /home/coder/.bashrc
echo "export PULUMI_SKIP_CONFIRMATIONS=true" >> /home/coder/.bashrc

# Start code-server with proper configuration
exec /usr/bin/entrypoint.sh \
    --bind-addr 0.0.0.0:8080 \
    --user-data-dir /home/coder/.local/share/code-server \
    --extensions-dir /home/coder/.local/share/code-server/extensions \
    --disable-telemetry \
    --auth password \
    /home/coder/workspace