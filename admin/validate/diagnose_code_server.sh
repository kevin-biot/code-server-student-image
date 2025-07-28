#!/bin/bash
# Make sure script is executable
chmod +x "$0" 2>/dev/null || true

echo "=== Code-Server File System Diagnostics ==="
echo "Student Instance: $(whoami)"
echo "Current Directory: $(pwd)"
echo "Home Directory: $HOME"
echo ""

echo "=== File System Permissions Check ==="
echo "Current user ID: $(id)"
echo "Home directory permissions:"
ls -la $HOME
echo ""

echo "=== Workspace Directory Analysis ==="
if [ -d "$HOME/workspace" ]; then
    echo "Workspace exists - checking permissions:"
    ls -la $HOME/workspace
    echo ""
    
    echo "Labs directory contents:"
    if [ -d "$HOME/workspace/labs" ]; then
        ls -la $HOME/workspace/labs
    else
        echo "Labs directory not found!"
    fi
else
    echo "Workspace directory not found!"
fi
echo ""

echo "=== Mount Points Check ==="
echo "Checking mounted filesystems:"
df -h
echo ""

echo "=== Code-Server Process Check ==="
echo "Code-server processes:"
ps aux | grep code-server | grep -v grep
echo ""

echo "=== Environment Variables ==="
echo "Relevant environment variables:"
env | grep -E "(HOME|USER|WORKSPACE|CODE_SERVER)" | sort
echo ""

echo "=== File System Type ==="
echo "File system type for workspace:"
stat -f $HOME/workspace 2>/dev/null || stat --file-system $HOME/workspace 2>/dev/null
echo ""

echo "=== Kubernetes Pod Info (if available) ==="
if command -v kubectl &> /dev/null; then
    echo "Pod name: $HOSTNAME"
    kubectl get pod $HOSTNAME -o yaml 2>/dev/null | grep -A 10 -B 5 "volumes\|volumeMounts" || echo "kubectl not available or no permissions"
else
    echo "kubectl not available"
fi
echo ""

echo "=== Code-Server Settings Check ==="
echo "Code-server config location:"
find $HOME -name "*.json" -path "*code-server*" 2>/dev/null
echo ""

echo "=== Checking for .vscode directory ==="
if [ -d "$HOME/.vscode" ]; then
    echo "VS Code settings found:"
    ls -la $HOME/.vscode
else
    echo "No .vscode directory found"
fi

echo ""
echo "=== Testing File Creation ==="
test_file="$HOME/workspace/test_permissions.txt"
if touch "$test_file" 2>/dev/null; then
    echo "✓ Can create files in workspace"
    rm "$test_file"
else
    echo "✗ Cannot create files in workspace"
fi