#!/usr/bin/env bash
# clone-workshop-repos.sh
# ------------------------------------------------------------
# Clone / update the "golden" workshop repos **into the right
# lab folder** so students can simply `cd labs/dayX-…` and go.
# Updated to use instructor-prebuilt approach for Day 1
# ------------------------------------------------------------
set -euo pipefail

WORKSPACE="${WORKSPACE_DIR:-$HOME/workspace}"

# ── Map repo → destination dir ──────────────────────────────
declare -A MAP=(
  # Day-1 Pulumi exercises (using main branch with instructor-prebuilt approach)
  ["https://github.com/kevin-biot/IaC.git"]="$WORKSPACE/labs/day1-pulumi/IaC"

  # Day-2 Tekton / Shipwright CI-CD
  ["https://github.com/kevin-biot/devops-workshop.git"]="$WORKSPACE/labs/day2-tekton/devops-workshop"

  # Example for Day-3 GitOps (uncomment / add more as needed)
  # ["https://github.com/kevin-biot/gitops-demo.git"]="$WORKSPACE/labs/day3-gitops/gitops-demo"
)

echo "📥 Cloning / updating workshop repos (instructor-prebuilt approach)…"
for REPO in "${!MAP[@]}"; do
  DEST="${MAP[$REPO]}"
  if [[ -d "$DEST/.git" ]]; then
    echo "🔄  Updating $(basename "$DEST") in $DEST (branch: main)"
    # make sure the main branch exists locally and is current
    git -C "$DEST" fetch origin main:main                  # grab latest main
    git -C "$DEST" checkout main                           # switch if needed
    git -C "$DEST" pull --quiet --rebase                   # fast update
  else
    echo "⬇️  Cloning $REPO → $DEST (branch: main)"
    mkdir -p "$(dirname "$DEST")"
    git clone --depth 1 --branch main "$REPO" "$DEST"     # clone main directly
  fi
done

echo "✅ Repositories ready for instructor-prebuilt workshop approach."
echo "📋 Day 1: Focus on Pulumi Infrastructure as Code concepts"
echo "🏗️ Uses pre-built images for reliable, fast deployments"