#!/bin/bash
# clone-workshop-repos.sh - Clone DevOps workshop repositories into the workspace

set -euo pipefail

WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace}"
REPOS=(
    "https://github.com/kevin-biot/IaC.git"
    "https://github.com/kevin-biot/devops-workshop.git"
)

mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

for repo in "${REPOS[@]}"; do
    name=$(basename "$repo" .git)
    if [ -d "$name" ]; then
        echo "[INFO] $name already cloned, skipping"
    else
        echo "[INFO] Cloning $repo"
        git clone "$repo"
    fi
done
