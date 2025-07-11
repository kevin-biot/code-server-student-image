# Code Server Student Image

A self-contained OpenShift deployment for providing individual code-server environments to students.

## Features

- **Complete Development Environment**: Pre-installed with Python, Node.js, Java, Docker, kubectl, oc CLI, and Helm
- **Laptop-Free Workshop**: No student setup required - everything runs in the browser
- **Student Quick Start Guide**: Comprehensive guide for students new to code-server/VS Code
- **Multi-Student Support**: Template-based deployment for easy scaling
- **Security**: Network policies, resource quotas, and RBAC for student isolation
- **Persistent Storage**: Each student gets their own workspace that persists
- **Auto-Configuration**: Welcome materials and git configuration templates

## Quick Start

### 1. Build the Image

The project uses Shipwright for automated builds:

```bash
./build-and-verify.sh
```
The script detects whether you are on an `x86_64` or `arm64` system and passes
the correct architecture to Shipwright so multi-arch builds work out of the box.

You can override the default build timeout by setting the `BUILD_TIMEOUT`
environment variable before running the script.

### 2. Deploy Students

Use the management script to deploy multiple student environments:

```bash
# Make the script executable
chmod +x deploy-students.sh

# Deploy 5 students (student01-student05)
./deploy-students.sh -n 5 -d apps.your-cluster.com

# Force redeploy if namespaces already exist
./deploy-students.sh -n 5 -d apps.your-cluster.com --force

# Deploy specific students
./deploy-students.sh -s alice,bob,charlie -d apps.your-cluster.com

# Clean up environments
./deploy-students.sh -n 5 --cleanup
```

If a student's namespace already exists, the script logs a warning and skips deployment. Use `--force` to redeploy.

### 3. Access Student Environments

After deployment, each student will have:
- A unique URL: `https://studentXX-code-server.apps.your-cluster.com`
- A generated password (saved in `student-credentials.txt`)
- Their own isolated namespace with resource limits
- **STUDENT-QUICK-START.md** guide for first-time users

**For students new to code-server/VS Code**: Direct them to click on `STUDENT-QUICK-START.md` in their workspace file explorer for a complete tutorial on using the environment.

### 4. Populate Workspace with Workshop Repos (optional)
Run the helper script inside a student terminal to clone the training repositories:
```bash
./clone-workshop-repos.sh
```

## Architecture

### Image Contents
- **Base**: Latest code-server from Coder
- **Languages**: Python 3, Node.js, Java 17
- **Tools**: Git, Docker, kubectl, oc CLI, Helm, Maven, Gradle
- **Extensions**: Python, YAML, JSON, Kubernetes, Docker extensions pre-installed

### OpenShift Resources
Each student gets their own namespace with:
- **Deployment**: Single replica code-server pod
- **Service**: Internal cluster access
- **Route**: External HTTPS access
- **PVCs**: `code-server-pvc` for the workspace and `shared-pvc` for Tekton pipelines
- **ResourceQuota**: CPU/memory limits
- **NetworkPolicy**: Isolation from other students
- **RBAC**: Limited permissions within their namespace

## Configuration

### Resource Limits (per student)
- **CPU**: 200m request, 1000m limit
- **Memory**: 1Gi request, 2Gi limit
- **Storage**: 1Gi persistent volume
- **Pods**: Maximum 5 pods per namespace

### Customization
- Modify `student-template.yaml` to adjust resources or add components
- Update `Dockerfile` to include additional tools or languages
- The `Dockerfile` creates `/home/coder/workspace/...` directories as `root`
  before switching to user `1001`.
- Edit `startup.sh` to customize the welcome experience

## Files

- `Dockerfile` - Enhanced code-server image with development tools
- `student-template.yaml` - OpenShift template for multi-student deployment
- `deploy-students.sh` - Management script for student environments
- `startup.sh` - Custom startup script with welcome message
- `gitconfig-template` - Git configuration template
- `shipwright/` - Build automation configuration
- Legacy files (for reference):
  - `code-server-*.yaml` - Original single-student deployment
  - `htpasswd-oauth.yaml` - OAuth configuration
  - `users.htpasswd` - User authentication

## Security Features

- **Network Isolation**: Students cannot access each other's environments
- **Resource Quotas**: Prevent resource exhaustion
- **RBAC**: Limited permissions within student namespaces
- **Non-root**: Container runs as non-privileged user (1001)
- **TLS**: All external access is encrypted

## Monitoring

Check student environment status:

```bash
# List all student namespaces
oc get namespaces -l student

# Check resource usage
oc get resourcequota -A | grep student

# Monitor deployments
oc get deployments -A | grep code-server
```

## Troubleshooting

### Common Issues

1. **Build fails**: Check Shipwright build logs
   ```bash
   oc logs -f buildrun/code-server-student-image-xxxxx -n devops
   ```

2. **Student can't access environment**: Verify route and service
   ```bash
   oc get route -n studentXX
   oc get pods -n studentXX
   ```

3. **Resource issues**: Check quotas and limits
   ```bash
   oc describe resourcequota -n studentXX
   ```

### Cleanup

Remove all student environments:
```bash
./deploy-students.sh -n 50 --cleanup  # Adjust number as needed
```

## Contributing

1. Fork the repository
2. Make your changes
3. Test with a small number of students
4. Submit a pull request

## License

This project is licensed under the [MIT License](LICENSE).
