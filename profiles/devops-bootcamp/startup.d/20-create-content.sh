#!/bin/bash
# 20-create-content.sh - Copy course content into workspace
# Content files are mounted from a ConfigMap at /home/coder/course-content/

CONTENT_DIR="/home/coder/course-content"

if [ -d "$CONTENT_DIR" ]; then
    # Copy content files to their destinations
    [ -f "$CONTENT_DIR/welcome-readme.md" ] && cp "$CONTENT_DIR/welcome-readme.md" /home/coder/workspace/README.md
    [ -f "$CONTENT_DIR/labs-readme.md" ] && cp "$CONTENT_DIR/labs-readme.md" /home/coder/workspace/labs/README.md

    # Only copy day READMEs if they don't already exist (don't overwrite student work)
    [ -f "$CONTENT_DIR/day1-pulumi-readme.md" ] && [ ! -f /home/coder/workspace/labs/day1-pulumi/README.md ] && \
        cp "$CONTENT_DIR/day1-pulumi-readme.md" /home/coder/workspace/labs/day1-pulumi/README.md
    [ -f "$CONTENT_DIR/day2-tekton-readme.md" ] && [ ! -f /home/coder/workspace/labs/day2-tekton/README.md ] && \
        cp "$CONTENT_DIR/day2-tekton-readme.md" /home/coder/workspace/labs/day2-tekton/README.md
    [ -f "$CONTENT_DIR/day3-gitops-readme.md" ] && [ ! -f /home/coder/workspace/labs/day3-gitops/README.md ] && \
        cp "$CONTENT_DIR/day3-gitops-readme.md" /home/coder/workspace/labs/day3-gitops/README.md
fi

# Copy quick start guide to workspace
if [ -f /home/coder/STUDENT-QUICK-START.md ]; then
    cp /home/coder/STUDENT-QUICK-START.md /home/coder/workspace/STUDENT-QUICK-START.md
fi

# Set ownership
chown -R coder:coder /home/coder/workspace 2>/dev/null || true
