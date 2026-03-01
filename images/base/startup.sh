#!/bin/bash
set -e
# Generic training platform startup
# Profile-specific setup lives in startup.d/*.sh scripts

# Detect student namespace from environment or hostname
if [ -z "$STUDENT_NAMESPACE" ]; then
    STUDENT_NAMESPACE=$(echo "$HOSTNAME" | sed 's/code-server.*//' | sed 's/.*-//')
    if [ -z "$STUDENT_NAMESPACE" ]; then
        STUDENT_NAMESPACE="student01"
    fi
fi
export STUDENT_NAMESPACE

# Add tool-pack binaries to PATH
if [ -d /opt/tool-packs/bin ]; then
    export PATH="/opt/tool-packs/bin:$PATH"
    echo "export PATH=\"/opt/tool-packs/bin:\$PATH\"" >> /home/coder/.bashrc
fi

# Set up Git configuration from template
if [[ ! -f /home/coder/.gitconfig && -f /home/coder/.gitconfig-template ]]; then
    cp /home/coder/.gitconfig-template /home/coder/.gitconfig
    sed -i "s/STUDENT_ID/$STUDENT_NAMESPACE/g" /home/coder/.gitconfig
fi

# Export namespace to shell
echo "export STUDENT_NAMESPACE=$STUDENT_NAMESPACE" >> /home/coder/.bashrc

# Run profile startup scripts in sorted order
if [ -d /home/coder/startup.d ]; then
    for script in /home/coder/startup.d/*.sh; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            echo "[startup] Running $(basename "$script")..."
            . "$script" || echo "[startup] WARNING: $(basename "$script") failed, continuing..."
        fi
    done
fi

# Start code-server
exec code-server \
    --bind-addr 0.0.0.0:8080 \
    --disable-telemetry \
    --auth password \
    .
