# Cloud-Native Development Environment

Welcome to your cloud-native workspace! This environment is set up for Kubernetes and OpenShift development with Python scripting support.

## Pre-installed Tools

### Cloud Native
- OpenShift CLI (`oc`) - Platform management
- Kubernetes CLI (`kubectl`) - Container orchestration
- Helm - Package management and chart development
- Tekton CLI (`tkn`) - Pipeline operations
- ArgoCD CLI - GitOps workflows

### Languages
- Python 3 with pip and virtual environments

### Development Tools
- VS Code with YAML and Python extensions
- Git with completion
- JSON/YAML processors (jq, yq)

## Directory Structure

```
workspace/
├── projects/              # Your application code
├── labs/                  # Lab exercises
└── examples/
    ├── kubernetes/        # K8s manifest examples
    ├── helm/              # Helm chart examples
    └── python/            # Python automation scripts
```

## Quick Start

```bash
# Verify cluster access
oc whoami
oc project $STUDENT_NAMESPACE

# List cluster resources
kubectl get nodes
kubectl get namespaces

# Deploy a sample app
kubectl create deployment hello --image=nginx
kubectl expose deployment hello --port=80
oc expose svc/hello

# Check the route
oc get routes
```

## Helm Quick Start

```bash
# Search for charts
helm search hub wordpress

# Create your own chart
cd ~/workspace/projects
helm create my-chart

# Lint and template
helm lint my-chart/
helm template my-chart/
```

## Need Help?

- Use `Terminal > New Terminal` for command line access
- All CLI tools support `--help`
- Check `examples/` for reference manifests
