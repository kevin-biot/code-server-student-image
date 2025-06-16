#!/bin/bash
# startup.sh - Custom startup script for students

# Set up Git configuration if not already done
if [[ ! -f /home/coder/.gitconfig && -f /home/coder/.gitconfig-template ]]; then
    cp /home/coder/.gitconfig-template /home/coder/.gitconfig
fi

# Create welcome message
cat > /home/coder/workspace/README.md << 'EOF'
# Welcome to Your Development Environment

This code-server environment comes with the following tools pre-installed:

## Languages & Runtimes
- Python 3 (with pip and venv)
- Node.js & npm
- Java 17 (with Maven and Gradle)

## DevOps Tools
- Docker
- kubectl
- OpenShift CLI (oc)
- Helm

## Development Tools
- Git
- Various text editors (vim, nano)
- Build tools

## Directory Structure
- `projects/` - Your main project work
- `labs/` - Lab exercises and assignments
- `examples/` - Sample code and examples

## Getting Started
1. Open a terminal (Terminal → New Terminal)
2. Configure Git: `git config --global user.name "Your Name"`
3. Configure Git: `git config --global user.email "your.email@example.com"`
4. Start coding!

## Useful Commands
- `oc login` - Login to OpenShift cluster
- `kubectl get pods` - List Kubernetes pods  
- `python3 -m venv myenv` - Create Python virtual environment
- `npm init` - Initialize new Node.js project

Happy coding! 🚀
EOF

# Start code-server
exec /usr/bin/entrypoint.sh --bind-addr 0.0.0.0:8080 --user-data-dir /home/coder/.local/share/code-server --extensions-dir /home/coder/.local/share/code-server/extensions --disable-telemetry --auth password
