#!/usr/bin/env bash
# clone-workshop-repos.sh
# ------------------------------------------------------------
# Clone / update the “golden” workshop repos **into the right
# lab folder** so students can simply `cd labs/dayX-…` and go.
# ------------------------------------------------------------
set -euo pipefail

WORKSPACE="${WORKSPACE_DIR:-$HOME/workspace}"

# ── Map repo → destination dir ──────────────────────────────
declare -A MAP=(
  # Day-1 Pulumi exercises
  ["https://github.com/kevin-biot/IaC.git"]="$WORKSPACE/labs/day1-pulumi/IaC"

  # Day-2 Tekton / Shipwright CI-CD
  ["https://github.com/kevin-biot/devops-workshop.git"]="$WORKSPACE/labs/day2-tekton/devops-workshop"

  # Example for Day-3 GitOps (uncomment / add more as needed)
  # ["https://github.com/kevin-biot/gitops-demo.git"]="$WORKSPACE/labs/day3-gitops/gitops-demo"
)

echo "📥 Cloning / updating workshop repos …"
for REPO in "${!MAP[@]}"; do
  DEST="${MAP[$REPO]}"
  if [[ -d "$DEST/.git" ]]; then
    echo "🔄  Updating $(basename "$DEST") in $DEST (branch: dev)"
    # make sure the dev branch exists locally and is current
    git -C "$DEST" fetch origin dev:dev                    # grab latest dev
    git -C "$DEST" checkout dev                            # switch if needed
    git -C "$DEST" pull --quiet --rebase                   # fast update
  else
    echo "⬇️  Cloning $REPO → $DEST (branch: dev)"
    mkdir -p "$(dirname "$DEST")"
    git clone --depth 1 --branch dev "$REPO" "$DEST"       # clone dev directly
  fi
done

echo "✅ Repositories ready."
