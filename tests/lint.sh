#!/bin/bash
set -e
# lint.sh - Run linting checks across the project
# Usage: ./tests/lint.sh
#
# Checks: shell syntax, YAML validity, kustomize builds, secrets detection

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
WARN=0

pass() { ((PASS++)); echo "  PASS: $1"; }
fail() { ((FAIL++)); echo "  FAIL: $1"; }
warn() { ((WARN++)); echo "  WARN: $1"; }

echo "Lint Suite"
echo "=========="

# 1. Shell syntax check
echo ""
echo "--- Shell script syntax (bash -n) ---"
while IFS= read -r script; do
    if bash -n "$script" 2>/dev/null; then
        pass "$(echo "$script" | sed "s|$REPO_ROOT/||")"
    else
        fail "$(echo "$script" | sed "s|$REPO_ROOT/||") — syntax error"
    fi
done < <(find "$REPO_ROOT" -name "*.sh" -not -path "*/legacy/*" -not -path "*/node_modules/*" | sort)

# 2. Shellcheck (if available)
echo ""
echo "--- Shellcheck (optional) ---"
if command -v shellcheck &>/dev/null; then
    # Check key scripts only (not every script in admin/manage)
    KEY_SCRIPTS=(
        "$REPO_ROOT/images/base/startup.sh"
        "$REPO_ROOT/deploy/generate-overlay.sh"
        "$REPO_ROOT/tests/test-profile.sh"
        "$REPO_ROOT/tests/test-base-image.sh"
        "$REPO_ROOT/admin/admin-workflow.sh"
    )
    for script in "${KEY_SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            if shellcheck -S warning "$script" 2>/dev/null; then
                pass "shellcheck: $(basename "$script")"
            else
                warn "shellcheck warnings in: $(basename "$script")"
            fi
        fi
    done
else
    warn "shellcheck not installed, skipping (install with: brew install shellcheck)"
fi

# 3. YAML validation
echo ""
echo "--- YAML validation ---"
if command -v yq &>/dev/null; then
    while IFS= read -r yaml_file; do
        if yq e '.' "$yaml_file" > /dev/null 2>&1; then
            pass "$(echo "$yaml_file" | sed "s|$REPO_ROOT/||")"
        else
            fail "$(echo "$yaml_file" | sed "s|$REPO_ROOT/||") — invalid YAML"
        fi
    done < <(find "$REPO_ROOT" -name "*.yaml" -o -name "*.yml" | grep -v node_modules | grep -v legacy | sort)
else
    warn "yq not installed, skipping YAML validation"
fi

# 4. Kustomize build validation
echo ""
echo "--- Kustomize overlay builds ---"
if command -v kubectl &>/dev/null; then
    for overlay_dir in "$REPO_ROOT"/deploy/overlays/*/; do
        [ -f "$overlay_dir/kustomization.yaml" ] || continue
        overlay_name=$(basename "$overlay_dir")
        if kubectl kustomize "$overlay_dir" > /dev/null 2>&1; then
            pass "overlay: $overlay_name"
        else
            fail "overlay: $overlay_name — kustomize build failed"
        fi
    done
else
    warn "kubectl not installed, skipping kustomize validation"
fi

# 5. Secrets detection
echo ""
echo "--- Secrets scan ---"
SECRETS_FOUND=0
# Check for common password patterns in non-legacy, non-test files
while IFS= read -r line; do
    ((SECRETS_FOUND++))
    fail "potential secret: $line"
done < <(grep -rn --include="*.sh" --include="*.yaml" --include="*.yml" \
    -E '(password|passphrase|secret)\s*=\s*"[^$"][^"]{3,}"' \
    "$REPO_ROOT" 2>/dev/null \
    | grep -v legacy/ \
    | grep -v '.env.example' \
    | grep -v 'profile-schema.yaml' \
    | grep -v 'test-base-image.sh' \
    | grep -v 'description:' \
    | grep -v '# ' \
    | head -10 || true)

if [ "$SECRETS_FOUND" -eq 0 ]; then
    pass "no hardcoded secrets detected"
fi

# 6. Dockerfile validation
echo ""
echo "--- Dockerfile checks ---"
for dockerfile in "$REPO_ROOT"/Dockerfile "$REPO_ROOT"/Dockerfile.monolith "$REPO_ROOT"/images/*/Dockerfile "$REPO_ROOT"/images/tool-packs/*/Dockerfile; do
    [ -f "$dockerfile" ] || continue
    name=$(echo "$dockerfile" | sed "s|$REPO_ROOT/||")
    # Check for :latest
    if grep -q ":latest" "$dockerfile" 2>/dev/null; then
        warn "$name uses :latest tag"
    else
        pass "$name — no :latest tags"
    fi
done

echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "FAILED: $FAIL issue(s) found"
    exit 1
else
    echo ""
    echo "ALL PASSED ($PASS checks, $WARN warnings)"
fi
