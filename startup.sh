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

# Set up Pulumi environment to avoid passphrase prompts
export PULUMI_CONFIG_PASSPHRASE="workshop123"
export PULUMI_SKIP_UPDATE_CHECK=true
export PULUMI_SKIP_CONFIRMATIONS=true

# Set up Git configuration if not already done
if [[ ! -f /home/coder/.gitconfig && -f /home/coder/.gitconfig-template ]]; then
    cp /home/coder/.gitconfig-template /home/coder/.gitconfig
    sed -i "s/STUDENT_ID/$STUDENT_NAMESPACE/g" /home/coder/.gitconfig
fi

# Create comprehensive welcome message with updated Tekton/Shipwright approach
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

### 🏗️ Day 1: Infrastructure as Code with Pulumi + Tekton
- **Location**: `labs/day1-pulumi/`
- **Focus**: Cloud-native infrastructure with Tekton/Shipwright builds
- **Tools**: Pulumi, Tekton, Shipwright, OpenShift Routes
- **No Docker Required**: Uses cloud-native build pipelines

### 🔄 Day 2: Advanced CI/CD Pipelines
- **Location**: `labs/day2-tekton/`  
- **Focus**: Enterprise-grade CI/CD pipelines
- **Tools**: Tekton Pipelines, Triggers, GitOps integration

### 🔄 Day 3: GitOps with ArgoCD
- **Location**: `labs/day3-gitops/`
- **Focus**: Implement GitOps workflows and automation
- **Tools**: ArgoCD, Git workflows, Application sync

## 🛠️ Pre-installed Tools

### **Languages & Runtimes**
- ☕ **Java 17** with Maven and Gradle
- 🐍 **Python 3** with pip and virtual environments
- 🟢 **Node.js 20** with npm and TypeScript support
- 🔧 **Build tools** for all major languages

### **DevOps & Cloud Native**
- 🔴 **OpenShift CLI** (`oc`) - Platform management
- ⚙️ **Tekton CLI** (`tkn`) - Pipeline operations
- ☸️ **Kubernetes CLI** (`kubectl`) - Container orchestration
- 🏗️ **Pulumi CLI** - Infrastructure as Code (passphrase pre-configured)
- 📦 **Helm** - Package management
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
│   ├── day1-pulumi/   # Day 1: Infrastructure as Code + Tekton
│   ├── day2-tekton/   # Day 2: Advanced CI/CD Pipelines
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

### **Day 1: Pulumi + Tekton Infrastructure**
```bash
cd labs/day1-pulumi

# Clone workshop repository
git clone https://github.com/kevin-biot/IaC.git .

# Setup environment (no passphrase needed!)
npm install
pulumi login --local
pulumi stack init dev
pulumi config set studentNamespace $STUDENT_NAMESPACE

# Deploy with cloud-native builds
oc apply -f tekton/
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

### **Development Workflow (Updated for Tekton)**
```bash
# Create new project
mkdir projects/my-app && cd projects/my-app
git init

# Tekton build workflow
oc create -f tekton/pipeline-run.yaml
tkn pipelinerun logs --last -f

# Monitor builds and deployments
tkn pipeline list
oc get builds,buildruns
oc get pods

# GitOps management
argocd app list
argocd app sync my-app
```

## 🔗 Important Links

When your applications are deployed, you can access:

- 🌐 **Your Web Application**: Check `oc get routes` for URL
- 🖥️ **OpenShift Console**: `https://console-openshift-console.apps.cluster.domain`
- 📈 **Tekton Dashboard**: `https://tekton-dashboard.apps.cluster.domain`
- 🔄 **ArgoCD UI**: `https://argocd.apps.cluster.domain`

## 💡 Pro Tips

1. **Terminal Access**: Use `Terminal → New Terminal` for command line
2. **File Explorer**: Use the left sidebar to navigate files
3. **Git Integration**: Built-in Git support with visual diff
4. **Extensions**: Pre-installed extensions for YAML, Java, TypeScript
5. **Auto-completion**: Tab completion enabled for all CLI tools
6. **No Passphrases**: Pulumi passphrase pre-configured as `workshop123`
7. **Cloud Builds**: No Docker needed - all builds happen in Tekton/Shipwright

## 🆘 Need Help?

- **Documentation**: Check `examples/` directory for samples
- **Logs**: Use `oc logs`, `tkn logs`, or check OpenShift console
- **Debugging**: All tools support `--help` flag
- **Instructor**: Raise your hand or ask in chat

---

**🎯 Ready to start your cloud-native DevOps journey? Begin with Day 1 in the `labs/day1-pulumi` directory!**
EOF

# Set up Day 1 Pulumi exercise structure with updated approach
mkdir -p /home/coder/workspace/labs/day1-pulumi
cd /home/coder/workspace/labs/day1-pulumi

if [ ! -f README.md ]; then
    cat > README.md << 'EOF'
# Day 1: Infrastructure as Code with Pulumi + Tekton

## Objective
Use Pulumi with Tekton/Shipwright to provision cloud-native infrastructure including web application builds and database deployment.

## New Cloud-Native Approach
- ✅ **No Docker required** - Uses Tekton/Shipwright for builds
- ✅ **Enterprise-ready** - Real CI/CD pipeline patterns
- ✅ **Simplified setup** - No local Docker complexity

## Getting Started

1. **Clone workshop repository**:
   ```bash
   git clone https://github.com/kevin-biot/IaC.git .
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Initialize Pulumi (no passphrase needed!)**:
   ```bash
   pulumi login --local
   pulumi stack init dev
   pulumi config set studentNamespace $STUDENT_NAMESPACE
   ```

4. **Deploy Tekton build infrastructure**:
   ```bash
   oc apply -f tekton/
   ```

5. **Deploy infrastructure with Pulumi**:
   ```bash
   pulumi up
   ```

## Components You'll Build
- Tekton/Shipwright build pipeline for Node.js application
- PostgreSQL database deployment
- Web application deployment (using Tekton-built image)
- OpenShift route for external access
- RBAC and security policies

## Success Criteria
✅ Shipwright build completes successfully
✅ All pods running in OpenShift console
✅ Web application accessible via route
✅ Form submission works with database persistence
✅ No Docker required on student machine!
EOF
fi

# Set up Day 2 and Day 3 as before
mkdir -p /home/coder/workspace/labs/day2-tekton /home/coder/workspace/labs/day3-gitops

# Copy student quick start guide to workspace
if [ -f /home/coder/STUDENT-QUICK-START.md ]; then
    cp /home/coder/STUDENT-QUICK-START.md /home/coder/workspace/STUDENT-QUICK-START.md
fi

# Set up examples directory with useful references
mkdir -p /home/coder/workspace/examples/{kubernetes,tekton,pulumi,shipwright,argocd}

# Auto-login to OpenShift if credentials are available
if [ -n "$OPENSHIFT_TOKEN" ] && [ -n "$OPENSHIFT_SERVER" ]; then
    oc login --token="$OPENSHIFT_TOKEN" --server="$OPENSHIFT_SERVER" --insecure-skip-tls-verify=true
    oc project "$STUDENT_NAMESPACE" 2>/dev/null || echo "Note: Project $STUDENT_NAMESPACE not found"
fi

# Set up shell environment with all necessary variables
echo "export STUDENT_NAMESPACE=$STUDENT_NAMESPACE" >> /home/coder/.bashrc
echo "export PULUMI_SKIP_UPDATE_CHECK=true" >> /home/coder/.bashrc
echo "export PULUMI_SKIP_CONFIRMATIONS=true" >> /home/coder/.bashrc
echo "export PULUMI_CONFIG_PASSPHRASE=\"workshop123\"" >> /home/coder/.bashrc

# Create oc config to set default project context
mkdir -p /home/coder/.kube
cat > /home/coder/.kube/config << EOF
apiVersion: v1
kind: Config
current-context: default
contexts:
- context:
    cluster: ""
    namespace: $STUDENT_NAMESPACE
    user: ""
  name: default
EOF

# Start code-server with proper configuration
exec /usr/bin/entrypoint.sh \
    --bind-addr 0.0.0.0:8080 \
    --user-data-dir /home/coder/.local/share/code-server \
    --extensions-dir /home/coder/.local/share/code-server/extensions \
    --disable-telemetry \
    --auth password \
    /home/coder/workspace