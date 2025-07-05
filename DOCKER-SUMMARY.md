# Docker Container Summary: Code Server Student Image

## Overview

This Dockerfile creates a comprehensive, multi-architecture development environment based on the official code-server image. It's designed for DevOps workshops and provides students with a fully-equipped, browser-based IDE containing all necessary tools for cloud-native development.

## Base Image

**Base**: `ghcr.io/coder/code-server:latest`
- Provides VS Code in the browser via code-server
- Enables laptop-free workshop experiences
- Supports both ARM64 and AMD64 architectures

## Architecture Support

The container automatically detects and supports both:
- **x86_64/AMD64**: Standard Intel/AMD processors
- **aarch64/ARM64**: Apple Silicon, ARM-based systems

Architecture detection is handled dynamically during build time, ensuring cross-platform compatibility.

## Environment Configuration

### User Environment
- **Home Directory**: `/home/coder`
- **Working Directory**: `/home/coder/workspace`
- **Shell**: `/bin/bash`
- **User**: Non-root user (OpenShift compatible)

### Key Environment Variables
```bash
XDG_CONFIG_HOME=/home/coder/.config
XDG_DATA_HOME=/home/coder/.local/share
STUDENT_NAMESPACE=""                    # Set at runtime
PULUMI_SKIP_UPDATE_CHECK=true
PULUMI_SKIP_CONFIRMATIONS=true
PULUMI_CONFIG_PASSPHRASE="workshop123"  # Pre-configured for workshops
```

## Installed Software Stack

### Programming Languages & Runtimes

#### Node.js 20
- **Purpose**: Modern JavaScript/TypeScript development
- **Installation**: Via NodeSource repository
- **Includes**: npm package manager
- **Use Cases**: Web applications, build tools, Pulumi TypeScript

#### Python 3
- **Purpose**: Infrastructure automation, data processing
- **Includes**: pip, venv for virtual environments
- **Use Cases**: Automation scripts, infrastructure tools

#### Java 17
- **Purpose**: Enterprise application development
- **Includes**: OpenJDK 17, Maven, Gradle
- **Use Cases**: Spring Boot applications, enterprise microservices

### DevOps & Cloud Native Tools

#### Container & Kubernetes Tools
- **kubectl**: Kubernetes command-line tool
- **oc**: OpenShift CLI for Red Hat OpenShift
- **Helm**: Kubernetes package manager

#### CI/CD & Pipeline Tools
- **Tekton CLI (tkn)**: Cloud-native CI/CD pipelines
  - Version: 0.41.0
  - Architecture-aware installation
- **ArgoCD CLI**: GitOps continuous delivery
  - Version: 2.10.0

#### Infrastructure as Code
- **Pulumi CLI**: Modern infrastructure as code
  - Pre-configured with passphrase
  - Supports multiple cloud providers

### Development & Utility Tools

#### Core Utilities
```bash
git              # Version control
vim, nano        # Text editors
curl, wget       # HTTP clients
unzip, tree      # File utilities
htop, procps     # System monitoring
netcat, dnsutils # Network diagnostics
jq               # JSON processor
yq               # YAML processor (v4.45.4)
bash-completion  # Enhanced shell completion
```

#### Build Tools
```bash
build-essential  # GCC, make, etc.
maven           # Java build tool
gradle          # Java/Kotlin build tool
```

## VS Code Extensions

Pre-installed extensions for enhanced development experience:
- **redhat.vscode-yaml**: YAML language support
- **ms-vscode.vscode-typescript-next**: TypeScript support

## Workspace Structure

The container creates a structured workspace for organized development:

```
/home/coder/workspace/
├── projects/              # Student development projects
├── labs/
│   ├── day1-pulumi/      # Infrastructure as Code exercises
│   ├── day2-tekton/      # CI/CD pipeline exercises
│   └── day3-gitops/      # GitOps workflow exercises
├── examples/             # Reference examples and samples
└── templates/            # Workshop exercise templates
```

## Copied Files & Configuration

### Configuration Files
- **gitconfig-template**: Git configuration template with student placeholders
- **STUDENT-QUICK-START.md**: Comprehensive guide for first-time users

### Executable Scripts
- **startup.sh**: Primary initialization script
- **fix-gpgme-issue.sh**: GPG/security fixes
- **run-pipeline.sh**: Pipeline execution helper
- **start-pipeline.sh**: Pipeline startup helper

### Workshop Content
- **workshop-templates/**: Pre-built templates for exercises

## Security & OpenShift Compatibility

### User Permissions
- **Non-root execution**: Runs as user ID 1001
- **Group permissions**: Compatible with OpenShift Security Context Constraints
- **Directory ownership**: Properly configured for container security

### OpenShift Features
- **Security Context Constraints (SCC)**: Compatible with restricted SCCs
- **Random user IDs**: Supports OpenShift's random UID assignment
- **Group-writable files**: Required for OpenShift multi-user scenarios

## Container Startup Process

### Entry Point
```bash
ENTRYPOINT ["/bin/bash", "-c", "/home/coder/startup.sh || exec bash"]
```

### Startup Sequence
1. **Environment Detection**: Determines student namespace from hostname
2. **Configuration Setup**: Initializes Git configuration with student details
3. **Workspace Preparation**: Creates README and directory structure
4. **Tool Configuration**: Sets up Pulumi, kubectl, and other tools
5. **Welcome Content**: Generates comprehensive workshop guides
6. **Code Server Launch**: Starts VS Code server on port 8080

## Network & Accessibility

### Port Configuration
- **Code Server**: Port 8080 (HTTP)
- **Bind Address**: 0.0.0.0 (accepts connections from any interface)
- **Authentication**: Password-based (configured externally)

### Browser Access
- **Interface**: Full VS Code interface in web browser
- **Features**: File explorer, integrated terminal, extension support
- **Responsive**: Works on tablets and mobile devices

## Workshop-Specific Features

### Day 1: Infrastructure as Code with Pulumi
- Pre-configured Pulumi environment
- No passphrase prompts
- Tekton/Shipwright integration for builds
- Cloud-native approach (no local Docker required)

### Day 2: Advanced CI/CD with Tekton
- Tekton CLI pre-installed
- Pipeline templates and examples
- Integration with OpenShift builds

### Day 3: GitOps with ArgoCD
- ArgoCD CLI ready to use
- Git workflow templates
- Application synchronization tools

## Resource Requirements

### Minimum System Requirements
- **CPU**: 200m request, 1000m limit
- **Memory**: 1Gi request, 2Gi limit
- **Storage**: 1Gi persistent volume
- **Network**: Internet access for package installations

### Optimal Performance
- **CPU**: 500m+ for smooth development experience
- **Memory**: 2Gi+ for multiple simultaneous tools
- **Storage**: 2Gi+ for multiple projects

## Build Optimizations

### Multi-Stage Considerations
- Single-stage build for simplicity
- Layer optimization through combined RUN commands
- Package cache cleanup to reduce image size

### Performance Features
- **Timeout Protection**: 300-second timeout for extension installations
- **Error Handling**: Graceful fallbacks for network issues
- **Architecture Detection**: Automatic platform optimization

## Troubleshooting & Debugging

### Common Issues
1. **Extension Installation Timeouts**: Container continues with timeout fallback
2. **Permission Issues**: OpenShift-compatible permissions set during build
3. **Architecture Mismatches**: Auto-detection prevents platform issues

### Debug Tools Included
- **System Monitoring**: htop, procps for performance analysis
- **Network Diagnostics**: netcat, dnsutils for connectivity testing
- **Log Analysis**: Standard Unix tools for troubleshooting

### Health Checks
- **Tool Verification**: Node.js, npm versions verified during build
- **Directory Structure**: All required directories created
- **Permission Validation**: Ownership and permissions set correctly

## Integration Points

### External Services
- **OpenShift Clusters**: Direct integration via oc CLI
- **Git Repositories**: Pre-configured Git settings
- **Container Registries**: Compatible with enterprise registries
- **Cloud Providers**: Pulumi supports AWS, Azure, GCP, and more

### Educational Workflow
- **Self-Guided Learning**: Comprehensive documentation included
- **Progressive Complexity**: Day 1-3 structure for skill building
- **Real-World Tools**: Enterprise-grade tooling and practices

This container image serves as a complete, production-ready development environment that eliminates the need for complex local setups while providing students with hands-on experience using industry-standard DevOps tools and practices.
