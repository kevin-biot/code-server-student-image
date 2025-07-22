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

# Create comprehensive welcome message with updated instructor-prebuilt approach
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

### 🏗️ Day 1: Infrastructure as Code with Pulumi (Focus: IaC Concepts)
- **Location**: `labs/day1-pulumi/`
- **Focus**: Learning Infrastructure as Code with Pulumi
- **Tools**: Pulumi, Kubernetes, OpenShift Routes, PostgreSQL
- **Approach**: Uses instructor pre-built images for reliable, fast deployment

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
│   ├── day1-pulumi/   # Day 1: Infrastructure as Code with Pulumi
│   ├── day2-tekton/   # Day 2: Advanced CI/CD Pipelines
│   └── day3-gitops/   # Day 3: GitOps with ArgoCD
├── examples/          # Sample code and references
└── templates/         # Workshop exercise templates
```

## 🚀 Quick Start Commands

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
git clone https://github.com/kevin-biot/IaC

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
git clone https://github.com/kevin-biot/IaC
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

## 🔗 Important Links

When your applications are deployed, you can access:

- 🌐 **Your Web Application**: Check `pulumi stack output appUrl` or `oc get routes`
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
7. **Fast Deployment**: Day 1 uses pre-built images for reliable workshop experience

## 📋 Day 1 Learning Objectives

**Infrastructure as Code with Pulumi:**
- ✅ Understand declarative infrastructure management
- ✅ Learn resource dependencies and ordering
- ✅ Practice configuration management with secrets
- ✅ Experience infrastructure scaling and updates
- ✅ Explore Kubernetes networking and services
- ✅ Use OpenShift Routes for external access

**Key Concepts Demonstrated:**
- Pulumi stack management
- Resource providers and configurations
- Database deployment and persistence
- Application deployment patterns
- Service networking and discovery
- External access configuration

## 🆘 Need Help?

- **Documentation**: Check `examples/` directory for samples
- **Logs**: Use `oc logs`, `pulumi logs`, or check OpenShift console
- **Debugging**: All tools support `--help` flag
- **Instructor**: Raise your hand or ask in chat

---

**🎯 Ready to start your Infrastructure as Code journey? Begin with Day 1 in the `labs/day1-pulumi` directory!**
EOF

# Create Labs overview README (MISSING!)
mkdir -p /home/coder/workspace/labs
cat > /home/coder/workspace/labs/README.md << 'EOF'
# 📚 DevOps Workshop Labs

Welcome to your 3-day DevOps hands-on workshop!

## 🗓️ Workshop Structure

### Day 1: Infrastructure as Code with Pulumi
- **Directory**: `day1-pulumi/`
- **Duration**: 6-8 hours
- **Focus**: Learn declarative infrastructure with Pulumi
- **Tools**: Pulumi, Kubernetes, PostgreSQL
- **Key Learning**: IaC concepts, resource dependencies, scaling

### Day 2: CI/CD Pipelines with Tekton  
- **Directory**: `day2-tekton/`
- **Duration**: 6-8 hours
- **Focus**: Enterprise CI/CD automation
- **Tools**: OpenShift Pipelines, Tekton
- **Key Learning**: Pipeline automation, build processes

### Day 3: GitOps with ArgoCD
- **Directory**: `day3-gitops/`
- **Duration**: 6-8 hours
- **Focus**: Git-driven deployment workflows
- **Tools**: ArgoCD, Git workflows
- **Key Learning**: GitOps patterns, application lifecycle

## 🚀 Getting Started

1. **Start with Day 1**: Click `day1-pulumi/` → Read README.md
2. **Progress sequentially**: Complete each day before moving forward
3. **Ask for help**: Instructors are here to support you

## 📋 Prerequisites

### Day 1: Infrastructure Fundamentals
- ✅ OpenShift cluster access
- ✅ Basic terminal skills
- ✅ Container concepts (helpful)

### Day 2: Pipeline Development
- ✅ Completion of Day 1
- ✅ Git repository access
- ✅ CI/CD understanding

### Day 3: GitOps Implementation
- ✅ Completion of Days 1-2
- ✅ GitHub Personal Access Token
- ✅ Deployment patterns knowledge

## 💡 Success Tips

- 📖 **Read carefully**: Each day's README has important setup steps
- 💻 **Use the terminal**: All commands run in the integrated terminal
- 🔄 **Follow git workflows**: Clone repositories as instructed
- 🎯 **Focus on concepts**: Understanding beats speed
- 🤝 **Collaborate**: Help your fellow students

## 📊 Time Investment

- **Day 1**: 6-8 hours (infrastructure fundamentals)
- **Day 2**: 6-8 hours (pipeline development)  
- **Day 3**: 6-8 hours (GitOps implementation)
- **Total**: 18-24 hours of hands-on learning

Ready to build cloud-native infrastructure? **Start with Day 1!** 🚀
EOF

# Set up Day 1 Pulumi exercise structure with updated instructor-prebuilt approach
mkdir -p /home/coder/workspace/labs/day1-pulumi
cd /home/coder/workspace/labs/day1-pulumi

if [ ! -f README.md ]; then
    cat > README.md << 'EOF'
# Day 1: Infrastructure as Code with Pulumi

## 🎯 Objective
Learn Infrastructure as Code concepts using Pulumi to deploy a complete web application stack with database on OpenShift.

## 🚀 Workshop Approach: Focus on Learning IaC
- ✅ **Instructor pre-built images** - No build delays or complexity
- ✅ **Fast, reliable deployments** - Focus on Pulumi concepts
- ✅ **Workshop-optimized** - Maximum learning, minimum debugging
- ✅ **Production patterns** - Real infrastructure management

## 📋 What You'll Build
- PostgreSQL database deployment with persistent storage
- Node.js web application deployment using instructor-built image  
- Kubernetes services for internal networking
- OpenShift routes for external access
- Resource dependencies and configuration management
- Secrets handling and environment configuration

## 🛠️ Getting Started

### Step 1: Access Workshop Repository
```bash
# Navigate to the Day 1 directory
cd ~/workspace/labs/day1-pulumi

# Clone the IaC workshop repository
git clone https://github.com/kevin-biot/IaC

# Navigate to the main project
cd IaC
```

### Step 2: Initialize Pulumi Environment
```bash
# Install Node.js dependencies
npm install

# Initialize Pulumi (no passphrase needed!)
pulumi login --local
pulumi stack init dev

# Configure your environment
pulumi config set studentNamespace $STUDENT_NAMESPACE
pulumi config set --secret dbPassword MySecurePassword123

# Verify configuration
pulumi config
```

### Step 3: Preview Your Infrastructure
```bash
# See what Pulumi will create (dry run)
pulumi preview
```

**You should see:**
- ✅ Kubernetes Provider for your namespace
- ✅ PostgreSQL Deployment and Service
- ✅ Web Application Deployment (using pre-built image)
- ✅ Web Application Service
- ✅ OpenShift Route for external access

### Step 4: Deploy Your Infrastructure
```bash
# Deploy everything (fast - no builds needed!)
pulumi up

# Type 'yes' when prompted
```

### Step 5: Verify Your Deployment
```bash
# Get your application URL
pulumi stack output appUrl

# Check all deployed resources
oc get all -n $STUDENT_NAMESPACE

# Get the route URL
oc get routes -n $STUDENT_NAMESPACE

# Test your application
curl $(oc get route web-route -n $STUDENT_NAMESPACE -o jsonpath='{.spec.host}')
```

## 🔧 Learning Exercises

### Exercise 1: Understanding Resource Dependencies
1. **Examine the Pulumi code** - Open `index.ts` and understand:
   - How PostgreSQL is deployed first
   - How the web app depends on the database service
   - How the route depends on the web service

2. **Observe the deployment order** - Notice how Pulumi automatically handles dependencies

### Exercise 2: Configuration Management
1. **Update the database password**:
   ```bash
   pulumi config set --secret dbPassword NewSecurePassword456
   pulumi preview  # See what will change
   pulumi up       # Apply the change
   ```

2. **Observe how secrets are handled** - Notice encrypted values in config

### Exercise 3: Infrastructure Scaling
1. **Scale your web application** - Edit `index.ts`:
   ```typescript
   spec: {
     replicas: 3, // Change from 1 to 3
     // ... rest of configuration
   }
   ```

2. **Apply the scaling**:
   ```bash
   pulumi preview  # Preview the change
   pulumi up       # Apply scaling
   ```

3. **Monitor the scaling**:
   ```bash
   oc get pods -n $STUDENT_NAMESPACE -w
   ```

### Exercise 4: Infrastructure Updates
1. **Modify resource labels** - Add custom labels to your deployments
2. **Update environment variables** - Add new environment settings
3. **Change resource limits** - Modify CPU/memory allocations

### Exercise 5: Stack Management
1. **Export stack state**:
   ```bash
   pulumi stack export --file my-stack.json
   ```

2. **View resource details**:
   ```bash
   pulumi stack --show-urns
   ```

3. **Clean up resources**:
   ```bash
   pulumi destroy
   ```

## 🏗️ Architecture Deep Dive

### Resource Hierarchy
```
Pulumi Stack
├── Kubernetes Provider (namespace-scoped)
├── PostgreSQL Deployment
│   ├── Bitnami PostgreSQL container
│   ├── Environment variables (DB credentials)
│   ├── Health checks (readiness/liveness)
│   └── Persistent volume (emptyDir for workshop)
├── PostgreSQL Service
│   └── Internal ClusterIP (postgres-svc:5432)
├── Web Application Deployment
│   ├── Pre-built Node.js image (instructor-built)
│   ├── Database connection configuration
│   ├── Health checks
│   └── Dependency on PostgreSQL service
├── Web Application Service
│   └── Internal ClusterIP (web-svc:80 → 8080)
└── OpenShift Route
    └── External HTTPS access (web-route-{namespace}.apps.cluster.domain)
```

### Key Learning Points

**Infrastructure as Code Benefits:**
- 📝 **Declarative** - Describe desired state, not procedures
- 🔄 **Repeatable** - Same deployment every time
- 📊 **Trackable** - Version control your infrastructure
- 🔄 **Updatable** - Modify and redeploy safely
- 🗑️ **Disposable** - Easy cleanup and recreation

**Pulumi Concepts:**
- 🏗️ **Resources** - Infrastructure components
- 🔗 **Dependencies** - Automatic ordering and relationships
- ⚙️ **Configuration** - Environment-specific settings
- 🔐 **Secrets** - Encrypted sensitive data
- 📤 **Outputs** - Information about deployed resources
- 📚 **Stacks** - Isolated instances of your program

**Kubernetes Patterns:**
- 🏗️ **Deployments** - Declarative application management
- 🌐 **Services** - Stable network endpoints
- 🔗 **Routes** - External access to applications
- 🔐 **Secrets** - Secure configuration data
- 🏷️ **Labels** - Resource organization and selection

## ✅ Success Criteria

By the end of Day 1, you should have:
- ✅ **Deployed a complete web application stack** using Pulumi
- ✅ **Understanding of Infrastructure as Code concepts**
- ✅ **Experience with Pulumi configuration and secrets**
- ✅ **Knowledge of Kubernetes resource dependencies**
- ✅ **Ability to scale and update infrastructure**
- ✅ **Working web application** accessible via browser
- ✅ **Database persistence** verified through form submissions

## 🚀 Next Steps

- **Day 2**: Advanced CI/CD pipelines with Tekton
- **Day 3**: GitOps workflows with ArgoCD
- **Advanced**: Multi-environment deployments
- **Production**: Monitoring, logging, and observability

**🎉 Great job on completing Day 1! You've learned the fundamentals of Infrastructure as Code!**
EOF
fi

# Set up Day 2 and Day 3 as before
mkdir -p /home/coder/workspace/labs/day2-tekton /home/coder/workspace/labs/day3-gitops

# Return to workspace root so code-server opens in the right directory
cd /home/coder/workspace

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

# Create workshop-specific README for day2-tekton
cat > /home/coder/workspace/labs/day2-tekton/README.md << 'EOF'
# Java Webapp DevOps Workshop

## Workshop Kickoff Steps

Follow these exact steps in your code-server terminal for the workshop:

```bash
# 1. Navigate to your workshop directory
cd ~/workspace/labs/day2-tekton

# 2. Clone the workshop repository (development branch)
git clone -b dev https://github.com/kevin-biot/devops-workshop

# 3. Enter the project directory
cd devops-workshop

# 4. Make the setup script executable
chmod +x ./setup-student-pipeline.sh

# 5. Run the automated setup script
./setup-student-pipeline.sh
```

## What the Setup Script Does

The setup script will:
1. Prompt for your student namespace (e.g., student01)
2. Ask for Git repository URL (defaults to workshop repo)
3. Render all YAML templates with your namespace
4. Apply infrastructure resources to your namespace
5. Create a rendered directory with your personalized files

## Next Steps After Setup

After running the setup script:
1. Navigate to the rendered directory: `cd rendered_<your-namespace>`
2. Trigger a build: `oc create -f buildrun.yaml -n <your-namespace>`
3. Run the pipeline: `oc apply -f pipeline-run.yaml -n <your-namespace>`

For complete instructions, see the full README in the devops-workshop repository after cloning.
EOF

# Create workshop-specific README for day3-gitops
cat > /home/coder/workspace/labs/day3-gitops/README.md << 'EOF'
# Day 3: GitOps with ArgoCD Workshop

## 🚀 Quick Start

### Step 1: Clone YOUR student branch
```bash
cd ~/workspace/labs/day3-gitops
git clone -b student01 https://github.com/kevin-biot/argocd
cd argocd

# 🔍 VALIDATE: Confirm you're on your student branch
git branch --show-current
# Should output: student01
```

### Step 3: 📖 Continue with the exercise instructions
```bash
cat DAY3-GITOPS-README.md
# OR open DAY3-GITOPS-README.md in the file explorer
```

## 🔧 Your Environment
- **Namespace:** `student01` (replace with your number)
- **Username:** `student01` 
- **Password:** `DevOps2025!`
- **Git configured:** ✅ Ready for push operations

## 📁 Workshop Structure
```
~/workspace/labs/
├── day2-tekton/     # Previous day's work
└── day3-gitops/
    └── argocd/      # ← You are here after git clone
```

⚠️ **Important:** All detailed instructions are in the cloned repository's `DAY3-GITOPS-README.md` file.
EOF

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

# Fix file ownership and permissions for workshop environment
chown -R coder:coder /home/coder/workspace
chmod -R 444 /home/coder/workspace/**/*.md  # Make README files read-only to prevent accidental edits
chmod 755 /home/coder/workspace /home/coder/workspace/labs
chmod 755 /home/coder/workspace/labs/day1-pulumi /home/coder/workspace/labs/day2-tekton /home/coder/workspace/labs/day3-gitops

# Start code-server with proper configuration
# Start code-server with current directory instead of container path
exec code-server \
    --bind-addr 0.0.0.0:8080 \
    --disable-telemetry \
    --auth password \
    .