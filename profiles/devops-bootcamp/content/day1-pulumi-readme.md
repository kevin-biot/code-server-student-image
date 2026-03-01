# Day 1: Infrastructure as Code with Pulumi

## Objective
Learn Infrastructure as Code concepts using Pulumi to deploy a complete web application stack with database on OpenShift.

## Workshop Approach: Focus on Learning IaC
- **Instructor pre-built images** - No build delays or complexity
- **Fast, reliable deployments** - Focus on Pulumi concepts
- **Workshop-optimized** - Maximum learning, minimum debugging
- **Production patterns** - Real infrastructure management

## What You'll Build
- PostgreSQL database deployment with persistent storage
- Node.js web application deployment using instructor-built image
- Kubernetes services for internal networking
- OpenShift routes for external access
- Resource dependencies and configuration management
- Secrets handling and environment configuration

## Getting Started

### Step 1: Access Workshop Repository
```bash
# Navigate to the Day 1 directory
cd ~/workspace/labs/day1-pulumi

# Clone the IaC workshop repository
git clone <instructor-provided-repo-url>

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
- Kubernetes Provider for your namespace
- PostgreSQL Deployment and Service
- Web Application Deployment (using pre-built image)
- Web Application Service
- OpenShift Route for external access

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

## Learning Exercises

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

## Architecture Deep Dive

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
- **Declarative** - Describe desired state, not procedures
- **Repeatable** - Same deployment every time
- **Trackable** - Version control your infrastructure
- **Updatable** - Modify and redeploy safely
- **Disposable** - Easy cleanup and recreation

**Pulumi Concepts:**
- **Resources** - Infrastructure components
- **Dependencies** - Automatic ordering and relationships
- **Configuration** - Environment-specific settings
- **Secrets** - Encrypted sensitive data
- **Outputs** - Information about deployed resources
- **Stacks** - Isolated instances of your program

**Kubernetes Patterns:**
- **Deployments** - Declarative application management
- **Services** - Stable network endpoints
- **Routes** - External access to applications
- **Secrets** - Secure configuration data
- **Labels** - Resource organization and selection

## Success Criteria

By the end of Day 1, you should have:
- **Deployed a complete web application stack** using Pulumi
- **Understanding of Infrastructure as Code concepts**
- **Experience with Pulumi configuration and secrets**
- **Knowledge of Kubernetes resource dependencies**
- **Ability to scale and update infrastructure**
- **Working web application** accessible via browser
- **Database persistence** verified through form submissions

## Next Steps

- **Day 2**: Advanced CI/CD pipelines with Tekton
- **Day 3**: GitOps workflows with ArgoCD
- **Advanced**: Multi-environment deployments
- **Production**: Monitoring, logging, and observability

**Great job on completing Day 1! You've learned the fundamentals of Infrastructure as Code!**
